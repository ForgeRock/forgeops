# Deploying ForgeOps on OpenShift

The Helm chart supports OpenShift deployments natively: `platform.openshift.enabled: true`
switches the platform's exposure surface to the tested OpenShift posture (Routes, the
NetworkPolicy allowlist, the AM Service https port, Ingress suppressed, the ds-set-passwords
job's SCC pin omitted). This page is the reference for the procedure and the gotchas —
everything a deployer must set or decide is documented here; there is no dedicated OpenShift
values file (per platform review decision 2026-11-11: the mode flag applies the chart-side
posture, and the remaining per-deployer inputs — FQDN, storage classes — have no
chart-knowable default).

These steps were validated end-to-end on OpenShift 4.22.14 (CRC) with the full platform Ready
and the user journey passing (OIDC discovery, client credentials grant, user provisioning, DS
persistence, authentication) under a default-deny NetworkPolicy.

## Before you begin

- **Namespace UID range (the pattern's foundation).** restricted-v2 rejects the chart's stock
  `runAsUser: 11111` pins unless the namespace grants that UID. Annotate the project before
  first install:

  ```
  oc new-project forgeops
  oc annotate namespace forgeops \
    openshift.io/sa.scc.uid-range=11111/1 \
    openshift.io/sa.scc.supplemental-groups=0/1 --overwrite
  oc get namespace forgeops -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'
  # must print 11111/1 (verify; a plain annotate fails silently without --overwrite)
  ```

  Post-hoc annotation of a project OpenShift created is a documented-but-not-explicitly-
  supported mutation; baking the same annotations into a custom project template is the
  supported-by-construction form. Choose per your security team's posture.

- **cert-manager must be installed before the platform** (the chart's DS certificates are
  minted by pre-install hooks that fire only at install time). Install it the same way the
  other how-tos do:

  ```
  forgeops prereqs cert-manager
  ```

  The command installs the chart with CRDs enabled and is idempotent (a re-run upgrades an
  existing install).

- **Set your FQDN before first install** — it is expensive to change later. All chart-rendered
  Routes use `platform.ingress.hosts[0]` as their hostname, and AM FQDN-validates OAuth2
  requests: a Route under any other hostname returns `400 "FQDN ... is not valid"`.

- **Set your storage classes before first install** — StatefulSet `volumeClaimTemplates` are
  immutable; a wrong class means uninstall/reinstall.

## What the mode flag applies

`platform.openshift.enabled: true` sets:

- `platform.route.enabled` — the chart-rendered edge Routes (AM whole-host claim; IDM and UI
  routes split by path, mirroring the Ingress templates).
- `platform.networkPolicy.enabled` — the four-policy allowlist (same-namespace, DNS 5353,
  ingress from `openshift-ingress`, kube-API egress 443), written to coexist with a
  default-deny-all policy in the namespace. The kube-API policy exists because the chart's own
  jobs run `kubectl` — under deny-all they hang on `kubectl get secret` without it.
- `am.service.httpsPort: 81` — a second Service port literally named `https`. The OpenShift
  router resolves a Route's `targetPort` against the **service port name**; the chart's AM
  Service port is named `http` while targeting the container port `https`, so without this
  entry every AM Route renders an empty haproxy backend and 503s in every termination mode.
  (The number 81 never appears in any Route — the Route's `targetPort` is the *name* `https`.
  443 is the router's own edge-TLS listener, external to the chart; 81 is an internal alias
  for AM's real container port 8081 and could be any legal port number.)
- `platform.ingress.enabled: false` — exposure is Routes, not Ingress. Set
  `platform.ingress.enabled: true` explicitly if you need Ingress-based exposure on OpenShift.
- The `ds-set-passwords` job's stock `runAsUser: 0` pod pin is omitted — under the
  namespace-range pattern restricted-v2 rejects that pin; omitting the block lets the
  namespace's own UID range govern the job. An explicit `ds_set_passwords.podSecurityContext`
  in your values always wins.

Any of these can still be overridden explicitly (e.g. `platform.route.enabled: false` under
the mode renders no Routes).

## TLS termination: edge, by design

AM's 8081 port (the container port named `https`) is plain HTTP behind Tomcat's TLS-offload
connector — it does not terminate TLS. Passthrough Routes fail the handshake and reencrypt
Routes 503; **edge termination (TLS at the router) is the only working mode**, tested on
4.22.14. Security teams mandating reencrypt need an AM TLS-enabled image first.

## Route hostname and path claims

OpenShift grants the first Route claiming a host an exclusive claim — a second Route for the
same host with no path renders `HostAlreadyClaimed` and never routes. The AM Route claims the
whole host (it owns `/am`, `/am/XUI`); the IDM/UI Routes claim their paths. Make the Route
host match the chart FQDN (a DNS alias), never the reverse.

## Secrets and passwords

- Secret material is not carried in values files. Use the chart's generation path
  (`values-helm-generate-secrets.yaml` / the `forgeops env` command) and pass generated
  passwords and keypairs as prefill.
- **Password rule (live-proven gotcha):** the default image line's PingDS ships an enabled
  common-password dictionary validator (32k words, substring match). Generate real random
  passwords — mixed case + digits, ≥16 chars, nothing word-like; `"abc123"` and
  dictionary-containing patterns are rejected at the ds-set-passwords step with a Constraint
  Violation. Example: `openssl rand -base64 24 | tr -d '/+=' | cut -c1-20`
- **Amster keypair (live-proven gotcha):** generate with `ssh-keygen -t rsa -b 2048 -m PEM`.
  OpenSSL PKCS#8 keys fail amster's BouncyCastle parse.

## Installing

Set your per-deployer inputs in your environment's values file (`helm/<ENV_NAME>/values.yaml`
through the standard `forgeops env` flow):

- `platform.ingress.hosts[0]` — your platform FQDN (the Routes' hostname; see above)
- `ds_idrepo.volumeClaimSpec.storageClassName` and `ds_cts.volumeClaimSpec.storageClassName` —
  your cluster's storage classes (StatefulSet `volumeClaimTemplates` are immutable; a wrong
  class means uninstall/reinstall)

Then install through the standard ForgeOps flow with the generated-secrets file alongside
(`values-helm-generate-secrets.yaml` provides the secret model the prefill requires).
Expected: ~8-15 minutes to all-Ready.

If Helm reports an amster hook timeout, the resources ARE installed — let workloads converge,
then re-run `helm upgrade` with the same values to settle release state. Do **not** uninstall
on a hook timeout.

## Image lines

Under the namespace-pinning pattern the default image line works as-is (validated). The alpine
line (`platform.imageRepository: .../images/alpine`, `platform.imageMode: forgeops`) is only
needed for the stricter native-conformance shape; note the alpine UI spelling difference
(`enduser-ui` vs `end-user-ui`).
