# Deploying ForgeOps on OpenShift

## Introduction

This document guides you to perform ForgeOps deployment on a OpenShift
cluster using the ForgeOps identity-platform Helm chart. It covers everything
from an empty project to a verified deployment: project setup, the environment
values, cert-manager, install, Routes, and end-to-end smoke tests.

The deployment pattern is **namespace UID pinning**: the project's UID range
is pinned to the platform UID (11111) before install, so every platform pod
admits under OpenShift's `restricted-v2` security context constraint with no
chart changes, no image changes and no per-pod SCC exceptions. Only the UI
pods need a narrow exception (see Step 4).

Everything here was validated end to end on OpenShift 4.22 (CodeReady
Containers, single node): all pods Ready, Routes serving, and the platform
journey passing (OIDC discovery, client-credentials grant, authentication
journey, IDM provisioning, DS persistence) with the chart's NetworkPolicy
set applied.

## Prerequisites

* An OpenShift 4.12+ cluster where you can create projects and annotate
  namespaces (project-admin rights). `oc` and Helm 3 installed and logged in
  to the cluster. 4.12 is the first release that enforces the `restricted-v2`
  SCC this pattern relies on. (This guide was validated on 4.22.)
* A local clone of the ForgeOps repository, with the `bin/forgeops` command
  runnable from the repo root.
* **Cluster sizing.** A single-replica platform requests about 6.5 Gi memory
  and 1.6 CPU cores. On a compact or single-worker cluster, 16 Gi memory and
  4 vCPUs alongside the control plane is enough for a single-replica
  deployment. For larger profiles or more replicas, add workers.
* **DNS — decide the platform FQDN before installing.** All Routes use
  `platform.ingress.hosts[0]` as their hostname, and AM bakes the FQDN into
  its imported configuration — changing it later is expensive. The FQDN must
  resolve to the cluster's ingress router: either under the cluster's default
  apps domain (for example `forgeops.apps.example.com`) or a dedicated DNS
  record pointing at the router's load balancer. On managed clusters (ROSA,
  ARO, OpenShift Dedicated), use the provided apps domain.
* **TLS.** Routes use edge termination — TLS ends at the OpenShift router,
  because AM's 8081 container port ("https") is plain HTTP behind Tomcat's
  TLS-offload connector: `passthrough` fails the TLS handshake and
  `reencrypt` returns 503. (Security teams asking "why not reencrypt?" —
  that is why; a reencrypt-capable AM needs a TLS-enabled AM image.)
  Under the cluster's default apps domain the router's wildcard certificate
  covers you. For a custom domain, plan to install a certificate (see
  Step 7).
* **Storage class.** Check what your cluster provides with `oc get sc`. Any
  ReadWriteOnce-capable class works (gp3-csi, thin, lvms-vg, ...).
  StatefulSet volume claim templates are immutable — set the storage class
  correctly before the first install, or you will be uninstalling and
  reinstalling.
* **cert-manager** must be installed before the platform (Step 3).

## Step 1 — Create the project and pin the UID range

Create the project, then pin its UID range to the chart's platform UID
(11111) and its supplemental groups to 0:

```bash
oc new-project forgeops
oc annotate namespace forgeops \
  openshift.io/sa.scc.uid-range=11111/1 \
  openshift.io/sa.scc.supplemental-groups=0/1 --overwrite
```

Verify the annotation took (a plain `oc annotate` without `--overwrite` fails
silently, and a fresh project already carries a default range):

```bash
oc get namespace forgeops \
  -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'
# must print 11111/1
```

**Never let Helm create the namespace** (do not pass `--create-namespace`).
If the project is ever recreated, OpenShift assigns it a fresh random UID
range (for example `1000650000/10000`) and every platform pod is rejected at
admission with `must be in the ranges: [1000650000, ...]`. If you see that
error, the project lost its pin — re-run the two annotations above.

Post-hoc annotation of a project is a documented but not
explicitly-supported mutation; baking the same annotations into a custom
project template is the supported-by-construction form. Choose per your
security team's posture and record which variant you used.

## Step 2 — Create the environment

The `forgeops env` command generates an environment: a values file under
`helm/<name>/values.yaml` holding your FQDN, install-time secret generation,
and pod security settings. From the ForgeOps repo root, run:

```bash
bin/forgeops env --env-name openshift \
  --fqdn <YOUR_FQDN> \
  --skip-issuer
```

* `--env-name openshift` — the environment name; the values file lands at
  `helm/openshift/values.yaml` (pick any name; use it consistently in the
  later steps).
* `--fqdn` — the platform FQDN you decided in the prerequisites.
* `--skip-issuer` — no Ingress TLS issuer is created. Under the OpenShift
  mode flag (next) exposure is Routes, not Ingress, and the DS certificates
  use their own self-signed cert-manager Issuer created at install.

(The command also creates a `kustomize/overlay/<name>/` directory. Helm
does not deploy from it — it belongs to the deprecated Kustomize flow —
but keep it: `bin/forgeops amster import -e <name>` builds its re-import
Job from `kustomize/overlay/<name>/amster`.)

Then edit `helm/openshift/values.yaml` to add the two things the generated
file cannot know — the OpenShift mode flag and your cluster's storage class:

```yaml
platform:
  openshift:
    enabled: true
  # ... the rest of the generated platform section stays as is ...
ds_cts:
  # ... the generated ds_cts section stays as is ...
  volumeClaimSpec:
    storageClassName: <YOUR_STORAGE_CLASS>
ds_idrepo:
  # ... the generated ds_idrepo section stays as is ...
  volumeClaimSpec:
    storageClassName: <YOUR_STORAGE_CLASS>
```

`platform.openshift.enabled: true` is the OpenShift mode flag. It applies
the whole tested chart-side posture — do not set these by hand:

* OpenShift `Route` objects render for AM, IDM and the UIs; Ingress is
  suppressed.
* The NetworkPolicy allowlist renders (Step 5 adds one extra rule on
  single-node clusters).
* The AM Service gains a port named `https` (an internal alias for AM's
  plain-HTTP 8081 container port) that the Routes target.
* The `ds-set-passwords` job drops its stock `runAsUser: 0` pin, which
  `restricted-v2` would reject under the namespace-range pattern.

**Password rule:** the generated secrets comply, but if you ever prefill a
password by hand, make it genuinely random — mixed case plus digits, 16
characters or more, nothing word-like. The PingDS image ships a
common-password dictionary validator (32,000 words, substring matching), and
the `ds-set-passwords` job rejects dictionary passwords with a Constraint
Violation. A compliant generator:

```bash
openssl rand -base64 24 | tr -d '/+=' | cut -c1-20
```

## Step 3 — Install cert-manager

The chart's DS certificates are minted by cert-manager objects in pre-install
hooks that fire only at install time. If cert-manager is missing, or is
installed after the platform, DS boots into a certificate failure loop and
the platform needs a clean reinstall.

Install it with the ForgeOps prereqs command (a re-run is a no-op when
cert-manager is already present; pass `--upgrade` to upgrade an existing
install):

```bash
bin/forgeops prereqs cert-manager
```

Or by hand:

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager -n cert-manager \
  --create-namespace --set crds.enabled=true
```

Verify before continuing — all three pods Running (some platforms ship
cert-manager pre-installed; check first):

```bash
oc get pods -n cert-manager
```

## Step 4 — Grant the UI pods their image UID

The environment generated in Step 2 pins the three UI workloads to run as
UID 101 (`admin_ui`, `login_ui`, `end_user_ui` — their images own that UID
and need it for their read-only filesystem layout). UID 101 sits outside the
namespace's pinned range, so `restricted-v2` rejects the pods unless the
namespace's default service account may use the `anyuid` SCC:

```bash
oc adm policy add-scc-to-user anyuid -z default -n forgeops
```

This is deliberately narrow: the platform components (AM, IDM, DS) stay
under `restricted-v2` inside the pinned range, and only the UI pods —
non-root, no privilege escalation, all capabilities dropped, read-only root
filesystem — get the UID exception.

**Alternative — no SCC grant.** If your security team prefers no `anyuid`
grant, delete the three `runAsUser: 101` pins from
`helm/openshift/values.yaml` (leaving each UI's `podSecurityContext` empty).
OpenShift then injects an admitted UID from the namespace range into the UI
pods, under `restricted-v2`, with no SCC change. Both models were validated
end to end; pick one and use it consistently. The rest of this guide follows
the default (pins + grant).

## Step 5 — NetworkPolicy: the kube-API egress rule on single-node clusters

With the mode flag on, the chart renders a NetworkPolicy allowlist (pod
traffic within the namespace, DNS, ingress from the router, and egress to
the Kubernetes API on 443). On multi-node clusters this set is complete and
you can skip this step and continue with Step 6.

On **single-node clusters where the API server runs on the host network**
— CodeReady Containers is the common case — the chart's kube-API egress rule
does not match the host-network API endpoint. Every platform job that runs
`kubectl` (the keystore-create, ssh-keygen and amster jobs) then hangs with
`dial tcp <cluster-ip>:443: i/o timeout`, the install never completes, and
the Deployments that depend on the job-produced secrets (AM, IDM) never come
up. Apply one supplemental policy **before installing**, allowing egress to
the API endpoint directly:

```bash
API_EP=$(oc get endpoints kubernetes -n default \
  -o jsonpath='{.subsets[0].addresses[0].ip}')
oc apply -n forgeops -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: supplemental-kubeapi-egress-hostnetwork
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
    - ports:
      - port: 6443
        protocol: TCP
      to:
      - ipBlock:
          cidr: ${API_EP}/32
EOF
```

NetworkPolicy rules are additive — this supplemental policy coexists with
the chart's set and survives Helm upgrades (Helm only manages the objects it
renders). If your cluster serves the API on a different port than 6443,
adjust the port.

## Step 6 — Install the platform

```bash
helm upgrade -i identity-platform charts/identity-platform \
  -f helm/openshift/values.yaml -n forgeops --timeout 15m
```

The release name must equal the chart name (`identity-platform`): the
chart's migration tooling assumes the two match, and the release name
appears in resource labels — use it again in the uninstall step below.

Expected bring-up is 8–15 minutes to all-Ready on a fresh install (DS setup
on empty volumes takes the longest). Success looks like: all Deployments 1/1,
both DS StatefulSets 1/1, and the jobs Completed (`ssh-keygen`,
`keystore-create`, `ds-set-passwords`, `amster`).

If Helm reports an amster hook timeout, the resources ARE installed — the
hook completes on its own once AM is Ready. Let the workloads converge, then
re-run the same `helm upgrade` to settle the release state. Do **not**
uninstall on a hook timeout.

The amster job (which imports the platform configuration into AM) runs on
install only. To force a re-import later, set `amster.force: true` for one
upgrade (it stays on for every upgrade until you unset it), or run
`bin/forgeops amster import <profile> -e openshift -n forgeops` (profiles:
`default`, `am-only`).

## Step 7 — Routes

With the mode flag on, Routes render from the release:

```bash
oc get routes -n forgeops
```

You should see the `am` Route claiming your whole FQDN, plus the IDM and UI
path Routes: `idm` (`/openidm`), `idm-upload` (`/upload`), `idm-export`
(`/export`), `idm-admin` (`/admin`), `idm-openicf` (`/openicf`), `login-ui`
(`/am/XUI`), `end-user-ui` (`/enduser`), `admin-ui` (`/platform`), and —
only if you enabled the legacy `idm_admin_ui` component — `idm-api` (`/api`).

Two properties of this Route set matter:

* **One host, split by path.** OpenShift gives the first Route claiming a
  host an exclusive claim, so AM claims the whole host and everything else
  splits paths under it. The router serves the most specific path match, so
  `/am/XUI` goes to the login-ui Route while every other `/am/...` path goes
  to AM.
* **Route hostnames must equal the chart FQDN.** AM validates OAuth2
  requests against `platform.ingress.hosts[0]` — a discovery request under
  any other hostname returns `400 "FQDN ... is not valid"`. Point DNS at the
  chart FQDN, never the reverse.

**TLS certificates.** The rendered Routes carry no explicit certificate and
serve the router's default one. Under the cluster's default apps domain that
is the wildcard certificate and works as-is. For a custom domain, either
install the certificate on the router (self-managed clusters), or replace a
Route with a manually created, certificate-carrying one:

```bash
oc get route am -n forgeops -o yaml > am-route.yaml   # reference
oc delete route am -n forgeops
oc create route edge am --service=am --port=https \
  --hostname=<FQDN> --cert=fullchain.pem --key=privkey.pem -n forgeops
```

The manually created Route is not owned by the Helm release, so the next
`helm upgrade` fails on it (on Helm 4 with an apply conflict — the released
`am` Route still exists without Helm's ownership metadata). After the
planned `helm upgrade`, either delete the release's copy of the Route and
re-create the manual one, or re-adopt it by re-applying Helm's ownership
metadata to the manual Route:

```bash
oc annotate route am -n forgeops \
  meta.helm.sh/release-name=identity-platform \
  meta.helm.sh/release-namespace=forgeops --overwrite
oc label route am -n forgeops \
  app.kubernetes.io/managed-by=Helm --overwrite
```

## Step 8 — Verify

```bash
oc get pods -n forgeops
# all 1/1 and Running; the jobs (ssh-keygen, keystore-create,
# ds-set-passwords, amster) Completed
curl -sk https://<FQDN>/am/isAlive.jsp
# → "Server is ALIVE"
curl -sk https://<FQDN>/am/oauth2/realms/root/.well-known/openid-configuration | jq -r .issuer
# → https://<FQDN>/am/oauth2
curl -sk https://<FQDN>/openidm/info/ping | jq -r .state
# → ACTIVE_READY
curl -sk -o /dev/null -w "%{http_code}\n" https://<FQDN>/platform/
# → 200
```

(`curl -k` is only needed while the Routes serve a self-signed or
untrusted certificate — under a real certificate, drop it.)

A machine-to-machine token grant against the IDM provisioning client:

```bash
PROV=$(oc get secret amster-env-secrets -n forgeops \
  -o jsonpath='{.data.IDM_PROVISIONING_CLIENT_SECRET}' | base64 -d)
curl -sk -u "idm-provisioning:$PROV" \
  -d "grant_type=client_credentials&scope=fr:idm:*" \
  https://<FQDN>/am/oauth2/access_token | jq -r .access_token
# → an access token
```

An authentication journey — get the admin password, then authenticate. The
quick, header-based form needs no callbacks:

```bash
export AMADMIN_PW=$(oc get secret am-env-secrets -n forgeops \
  -o jsonpath='{.data.AM_PASSWORDS_AMADMIN_CLEAR}' | base64 -d)
curl -sk -X POST \
  -H "X-OpenAM-Username: amadmin" -H "X-OpenAM-Password: $AMADMIN_PW" \
  -H "Content-Type: application/json" \
  -H "Accept-API-Version: protocol=1.0,resource=2.1" \
  https://<FQDN>/am/json/realms/root/authenticate | jq -r '.tokenId[0:40]'
# → a tokenId
```

The full callback-based journey works too, with one gotcha: the client must
echo the complete callback structure — `type`, `output`, `input` **and
`_id`** — replacing only the input values. Submitting a bare `type`+`input`
structure makes AM restart the journey from the top (every submit returns
fresh callbacks instead of a token). `authId` values are single-use; a
rejected attempt consumes the journey.

## Uninstall and cleanup

To remove the platform, uninstall the Helm release:

```bash
helm uninstall identity-platform -n forgeops
```

This deletes everything Helm rendered: the Deployments, StatefulSets,
Services, Routes, ConfigMaps, Helm-owned secrets, the NetworkPolicy set, and
the completed jobs.

Several objects outlive the release. What remains, and how to remove it:

* **The DS PVCs** (`data-ds-cts-0`, `data-ds-idrepo-0`) are created by the
  StatefulSets' volume claim templates and are **not** deleted by
  `helm uninstall`. A reinstall reuses them — DS keeps its old data, which
  collides with freshly generated passwords. To wipe the data:

  ```bash
  oc delete pvc -l app.kubernetes.io/instance=identity-platform -n forgeops
  ```

* **The DS certificate objects** — cert-manager `Certificate`s `ds-ssl-cert`
  and `ds-master-cert`, the `selfsigned-issuer`, and their secrets
  `ds-ssl-keypair` and `ds-master-keypair` — are pre-install hooks that are
  only deleted when the install fails, so uninstall leaves them in place.
  On a reinstall they are reused as-is. To remove them:

  ```bash
  oc delete certificate ds-ssl-cert ds-master-cert -n forgeops
  oc delete issuer selfsigned-issuer -n forgeops
  oc delete secret ds-ssl-keypair ds-master-keypair -n forgeops
  ```

  (Delete the Certificates before the secrets, or cert-manager re-mints the
  secrets immediately.)

* **The `amster` secret** (the SSH keypair the ssh-keygen job created) is
  also not Helm-owned. If you delete it, the next install's ssh-keygen job
  generates a fresh keypair — only do this deliberately, because the old
  private key stops being able to reach existing AM pods' authorized keys
  (irrelevant on a clean reinstall, which recreates AM anyway):

  ```bash
  oc delete secret amster -n forgeops
  ```

* **The supplemental NetworkPolicy** (Step 5) is not Helm-owned. Delete it
  manually if you are tearing the namespace down completely:

  ```bash
  oc delete networkpolicy supplemental-kubeapi-egress-hostnetwork -n forgeops
  ```

* **The project itself** and its UID-range annotations. `helm uninstall`
  does not touch the namespace. To remove it entirely (this also deletes the
  two annotations from Step 1 — a fresh project will need them re-applied):

  ```bash
  oc delete project forgeops
  ```

Deleting the project removes everything inside it in one step — the PVCs,
the leftover secrets, the certificate objects and the supplemental policy —
so for a full teardown it is the simplest path.

cert-manager itself is a cluster-level dependency, not part of the release —
leave it installed unless nothing else on the cluster uses it.

To start over in a fresh namespace, delete the project (or run the cleanup
commands above), then re-run Step 1 (project creation with the UID-range
annotations) before reinstalling.

## Deployment choices and trade-offs

These are values-file choices, not chart changes — everything else in this
guide follows the chart defaults.

**Keystore job pod retention.** The chart's jobs default to
`restartPolicy: OnFailure`, so a failing pod is deleted by the Job controller
when the backoff limit is exceeded — before its logs can be read. For
troubleshooting installs, add this to the environment values file; each
failed attempt pod then survives with its logs, and the job's 12-hour TTL
cleans everything up afterwards:

```yaml
keystore_create:
  restartPolicy: Never
```

Restore the default (`OnFailure`, or just remove the override) for
long-lived environments.

**UI UID model.** Step 4 described the two options: the generated pins plus
the `anyuid` grant (default), or deleting the pins and relying on namespace
UID injection. Both are fully supported; the difference is which security
posture your team prefers.

**NetworkPolicy.** The mode flag renders the chart's allowlist, written to
coexist with a default-deny-all namespace policy. If your organization adds
its own egress restrictions or a cluster-level egress firewall, the platform
needs DNS (UDP/TCP 5353 to the cluster DNS), image-registry egress, and —
per Step 5 on single-node clusters — kube-API egress on 6443.

## Single-node validation vs production

The chart-side pattern is environment-agnostic — the UID-range annotation,
SCC admission, Route claims, edge termination and cert-manager ordering
behave identically on any OpenShift 4.12+ cluster (validated on 4.22).
What differs is the platform around the chart:

| Dimension | Single-node validation (CRC) | Production cluster |
| --- | --- | --- |
| Topology | One VM carries control plane and workloads | Dedicated workers; size from the chart's requests (~6.5 Gi / 1.6 cores single-replica). Production adds replicas — especially DS |
| Storage | Hostpath provisioner; data is disposable | A real CSI class (gp3-csi, thin, lvms-vg, ODF); on multi-zone clusters check topology / WaitForFirstConsumer. Set before first install (immutable claim templates) |
| DNS & TLS | Custom FQDN pointing at the VM; verification uses `curl -k` (router's self-signed default cert) | Real DNS (the cluster apps domain, or corporate DNS); real certificates per Route or on the router. Drop `-k` |
| Exposure | Router reachable through the VM's IP | A load balancer fronts the ingress router — nothing chart-side changes |
| Image delivery | Direct registry pulls | Proxied and/or mirrored registries (IDMS/ICSP, air-gapped); proxy CAs must be trusted by the nodes |
| Namespace governance | Direct annotation by a cluster admin | Projects usually come from a platform team; the UID-range annotation needs project-admin rights (a custom project template is the supported way to standardize it); ResourceQuota must fit the platform's requests |
| NetworkPolicy | The kube-API egress rule needs the supplemental host-network policy (Step 5) | The chart's set is complete on multi-node clusters |
| Cluster lifecycle | Never upgrades | Cluster upgrades drain nodes and evict pods: pod disruption budgets and DS replication matter; hook jobs may re-run on churn |

## Troubleshooting

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| Every pod `FailedCreate`: `must be in the ranges: [1000650000, ...]` | The project was recreated (or Helm created it) and lost the UID pin | Re-run the Step 1 annotations; never let Helm create the namespace |
| `exec container process ...: Permission denied` in a job's init container | A script mounted under the image's UID-owned home while the pod runs on an injected UID | Update the chart to a version with the neutral-mount fix (script and config mount outside the image home) |
| Every AM Route 503s | The AM Service lacks a port literally named `https` | Ensure the mode flag is set (`platform.openshift.enabled: true`) — it adds the port |
| `400 "FQDN ... is not valid"` from AM | Request hostname ≠ chart FQDN | Point the Route/DNS alias at the chart FQDN, never the reverse |
| `ds-set-passwords` Constraint Violation | Dictionary-rejected password | Regenerate the password (Step 2 rule) and update the secret |
| UI ReplicaSets `FailedCreate`: `runAsUser: Invalid value: 101` | The `anyuid` grant is missing while the pins are present | Add the grant (Step 4), or delete the three UI pins and use injection |
| Job pods stuck in `Running`, logging `dial tcp <ip>:443: i/o timeout` | Kube-API egress blocked: single-node cluster with a host-network API endpoint, not covered by the chart's rule | Apply the supplemental policy in Step 5 |
| Jobs running `kubectl` hang under a stricter (deny-all) posture | Kube-API egress blocked | Keep the chart's NetworkPolicy set enabled (it includes kube-API egress) |
| Helm reports an amster hook timeout | DS bring-up exceeded the Helm timeout; the resources ARE installed | Let workloads converge, re-run `helm upgrade`; never uninstall on a hook timeout |
| A failed job never re-runs on `helm upgrade` | Jobs are not re-rendered by upgrades (the amster job additionally gates on install-only) | Delete and recreate the Job, or set `amster.force: true` / run `forgeops amster import` |
| Failed keystore pod vanishes before logs are read | Default `restartPolicy: OnFailure` deletes it at backoff limit | Set `keystore_create.restartPolicy: Never` (see Deployment choices) |
