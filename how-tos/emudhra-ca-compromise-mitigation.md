# Mitigating the eMudhra CA compromise in ForgeOps images

The steps in this how-to explain how to apply a temporary mitigation for the
October 2026 eMudhra CA compromise (FORGEOPS-6985) to images built from the
ForgeOps `docker/` directory. The mitigation removes trust in the compromised
root CA from both the JDK truststore and the OS CA bundle inside each image,
and is safe to leave in place until fixed product patch releases are available.

> **NOTE**: The `rcs` and `gatling` images are excluded from this how-to. Contact
> your support representative for guidance on those images.

## Background

On 19 October 2026 the certificate authority eMudhra disclosed that the private
keys of several of its intermediate CA certificates had become publicly
recoverable. With those keys, anyone can mint a TLS certificate for any domain
that clients will accept. The affected chains anchor at the root certificate
**emSign ECC Root CA - G3**, which ships in the JDK `cacerts` truststore and the
OS CA bundle inside the ForgeOps base images at
`us-docker.pkg.dev/forgeops-public/images-base`.

The default ForgeOps deployment is **not inherently exposed**: pod-to-pod TLS
uses cluster-internal PKI (secret-agent / cert-manager), and public TLS
terminates at Traefik. However, any outbound TLS connection a pod makes to a
public endpoint using the image's trust stores can create exposure — in a
default deployment no such connections occur, but the following common
additions introduce them:

* Social login or upstream identity providers
* SAML federation partners
* Email or SMS gateways
* CAPTCHA services
* IDM connectors to SaaS endpoints
* IG reverse-proxy upstreams

Client-side protections (such as browser vendor blocking of the compromised
intermediates) do not extend to pod-to-pod or application-level TLS: those
connections trust whatever the image's trust stores contain. AM, IDM and IG
resolve outbound connections with the Java truststore assembled at
pod start: the image's JDK `cacerts` is copied first, then the image's OS CA
bundle is imported on top. Both sources still contain the compromised root in
the current base images, so **both stores must be cleaned in the image** — an
OS-only or JDK-only strip leaves the other path open.

## Affected images

| Image | Base | OS / JDK | Mitigation |
|---|---|---|---|
| `am` | images-base/am | Ubuntu 26.04 · Temurin 25 | Required — verified exposed on the current base |
| `idm` | images-base/idm | Debian 12 · Zulu 21 | Required — verified exposed on the current base |
| `ig` | images-base/ig | Debian 12 · Zulu 21 | Required — verified exposed on the current base |
| `ds` | images-base/ds | Debian 12 · Zulu 25 | Required — apply in full; the OS steps no-op |
| `ds-proxy` | images-base/ds | Debian 12 · Zulu 25 | Required — apply in full; the OS steps no-op |
| `amster` | images-base/amster | Debian 12 · Zulu 25 | Required — apply in full; the OS steps no-op |
| `am-config-upgrader` | images-base/am-config-upgrader | Debian 12 · Zulu 25 | Required — apply in full; the OS steps no-op |
| admin-ui · end-user-ui · login-ui | gcr.io platform-*-ui | Alpine · nginx, no JVM | Not required — they make no outbound TLS trust decisions |

The mitigation block is idempotent: re-running it on an already-clean image
exits 0, and it fails the build only if the truststore is genuinely unreadable
or the root survives deletion. On a future fixed base it removes nothing and
the build succeeds.

Do not hardcode a keytool alias: JDK vendors spell the alias differently, as
verified by live `keytool` listings.

* Zulu (ds, idm, ig, amster, am-config-upgrader): `emsigneccrootcag3 [jdk]`
* Temurin (am): `cn_emsign_ecc_root_ca__g3,o_emudhra_technologies_limited,ou_emsign_pki,c_in [jdk]`

## Apply the mitigation

Add the following block to every Dockerfile listed above. It removes trust in
**emSign ECC Root CA - G3 only** — the root the compromised intermediates chain
to, and the same root Debian's and Ubuntu's `ca-certificates` fixes remove. It
leaves *emSign Root CA - G1/G2* and *emSign ECC Root CA - C3* untouched.

```dockerfile
# BEGIN TEMPORARY eMudhra mitigation (FORGEOPS-6985)
# Removes trust in "emSign ECC Root CA - G3" only (the compromised root).
# Leaves "emSign Root CA - G1/G2" and "emSign ECC Root CA - C3" untouched.
# Self-noops on a future fixed base. Remove once fixed patch releases ship.
USER root
RUN set -eux; \
    keytool -list -cacerts -storepass changeit >/dev/null; \
    keytool -list -v -cacerts -storepass changeit 2>/dev/null \
        | sed -n 's/^Alias name: //p' \
        | grep -i emsign | grep -i ecc | grep -i 'g3' \
        | while IFS= read -r a; do \
              keytool -delete -cacerts -storepass changeit -alias "$a" || true; \
          done; \
    if keytool -list -v -cacerts -storepass changeit 2>/dev/null \
        | sed -n 's/^Alias name: //p' \
        | grep -i emsign | grep -i ecc | grep -qi 'g3'; then \
          echo 'ERROR: emSign ECC Root CA - G3 still trusted by the JDK cacerts' >&2; \
          exit 1; \
    fi; \
    rm -f /usr/share/ca-certificates/mozilla/emSign_ECC_Root_CA_-_G3.crt; \
    sed -i '/emSign_ECC_Root_CA_-_G3\.crt$/d' /etc/ca-certificates.conf; \
    update-ca-certificates --fresh
# END TEMPORARY eMudhra mitigation
```

Place the block **after any `apt-get` line** so a later package install cannot
restore the OS copy of the certificate, and close it by restoring the image's
runtime user (`USER 11111`, or `USER forgerock` where that is the Dockerfile's
existing convention — both name the same uid 11111 user).

| Image | Where to insert | Runtime user after the block |
|---|---|---|
| `am` | after the `apt-get install -y --no-install-recommends jq` line | `USER 11111` |
| `idm` | inside the existing root block, after the openssl install | `USER 11111` |
| `ds` | in the root section, after the `ncat dnsutils` install | `USER forgerock` |
| `ds-proxy` | new block after the `COPY debian-buster-sources.list` line | `USER 11111` |
| `ig` | new block after the `COPY debian-buster-sources.list` line | `USER 11111` |
| `amster` | after the `apt-get install -y openldap-utils jq wget` line | `USER forgerock` |
| `am-config-upgrader` | after the `RUN chown 11111:11111 /home/forgerock` line | none — the image runs as root |

## Complementary package update

Fixed `ca-certificates` packages are available for the bookworm and Ubuntu
suites — `20250419~deb12u2` (bookworm-security) and
`20260816ubuntu0.26.04.1` (Ubuntu 26.04 updates) — and installing them removes
the OS copy of the root. The manual strip remains the primary control; this is
a complement.

> **NOTE**: Do not add this step to images that pin buster apt sources
> (`ds-proxy`, `ig`) — no fixed package exists for buster, and mixing suite
> sources risks package breakage.

```dockerfile
RUN apt-get update && apt-get install -y --only-upgrade ca-certificates
```

## Optional: vendored product truststore in IDM

The IDM image ships a vendored truststore at `/opt/openidm/security/truststore`
that still contains the root. The default ForgeOps wiring does not use it (IDM's
`boot.properties` points at `/opt/openidm/idmtruststore`), but if you override
that setting, add this inside the same root RUN:

```dockerfile
    if [ -f /opt/openidm/security/truststore ]; then \
        keytool -list -v -keystore /opt/openidm/security/truststore -storepass changeit 2>/dev/null \
            | sed -n 's/^Alias name: //p' \
            | grep -i emsign | grep -i ecc | grep -i 'g3' \
            | while IFS= read -r a; do \
                  keytool -delete -keystore /opt/openidm/security/truststore -storepass changeit -alias "$a" || true; \
              done; \
    fi
```

## Verify your deployment

Run these from **inside the pods** — host-side checks do not reflect pod trust.
Test after restarting the pods on the rebuilt images.

**Expected results**: the `dv-g3b` probe endpoints fail (curl exit 60,
`verify error:num=20`, JVM prints `BLOCKED`). An HTTP 200 response means the
deployment still trusts the compromised intermediates.

OS-layer probes:

```bash
# AM (has curl):
kubectl exec -n <namespace> deploy/am -- \
  curl -sS -o /dev/null -w '%{http_code}\n' --max-time 15 \
  https://dv-g3b-emudhra.we-have-a-problem.com/
# Expected: curl error 60 (unable to get local issuer certificate) — NOT 200

# DS / IDM / IG (openssl present in the base images):
kubectl exec -n <namespace> <ds-pod> -c ds -- \
  sh -c 'echo | openssl s_client -connect dv-g3b-emudhra.we-have-a-problem.com:443 -brief 2>&1 | head -5'
# Expected: verify error:num=20 (unable to get local issuer certificate) / handshake failure
```

JVM-layer probe (all Java images — am, idm, ig, ds, amster, am-config-upgrader):

```bash
kubectl exec -n <namespace> deploy/am -- bash -c 'cat > /tmp/T.java <<"EOF"
import javax.net.ssl.*; import java.net.*;
public class T { public static void main(String[] a) throws Exception {
  for (String u : new String[]{"https://dv-g3b-emudhra.we-have-a-problem.com/",
                               "https://dv-g3b-aaa-emudhra.we-have-a-problem.com/"}) {
    HttpsURLConnection c = (HttpsURLConnection) new URL(u).openConnection();
    c.setConnectTimeout(12000); c.setReadTimeout(12000);
    try { System.out.println(u + " -> CODE=" + c.getResponseCode()
          + " (STILL TRUSTED - FIX NOT IN EFFECT)"); }
    catch (Exception e) { Throwable r = e; while (r.getCause()!=null) r=r.getCause();
      System.out.println(u + " -> BLOCKED: " + r.getClass().getSimpleName()); }
  } } }
EOF
java /tmp/T.java'
# Expected: BLOCKED (SunCertPathBuilderException) for both hosts
```

Runtime truststore contents:

```bash
# AM runtime truststore — the store AM actually uses:
kubectl exec -n <namespace> deploy/am -- \
  sh -c 'keytool -list -v -keystore /home/forgerock/amtruststore -storepass changeit 2>/dev/null | grep -i "Owner: CN=emSign ECC Root CA - G3"'
# Expected: no output

# IDM runtime truststore:
kubectl exec -n <namespace> deploy/idm -- \
  sh -c 'keytool -list -v -keystore /opt/openidm/idmtruststore -storepass changeit 2>/dev/null | grep -i "Owner: CN=emSign ECC Root CA - G3"'
# Expected: no output
```

Build-time check (CI, after building a child image):

```bash
docker run --rm --entrypoint /bin/bash <child-image> -c \
  'keytool -list -cacerts -storepass changeit 2>/dev/null | grep -i emsign; ls /etc/ssl/certs | grep -i "emSign_ECC_Root_CA_-_G3" || echo "OS copy absent"'
# Expected: no ECC G3 entry in cacerts (RSA G1/G2 and ECC C3 may remain);
# "OS copy absent"
```

> **NOTE**: Only use `https://dv-g3b-emudhra.we-have-a-problem.com/` and
> `https://dv-g3b-aaa-emudhra.we-have-a-problem.com/` as probes.
> `https://emudhra.we-have-a-problem.com/` is a Let's Encrypt-secured portal
> page: its certificate does not chain through the compromised CA, and it
> returns HTTP 200 whether or not the fix is in effect.

## Limitations

* **Only one root is removed.** Eight intermediate CAs were compromised. Every
  chain observed, and both the Debian and Ubuntu package fixes, anchor at
  *emSign ECC Root CA - G3* — but if any compromised intermediate chains
  through a different root, this mitigation does not cover it.
* **Cross-signed paths.** A chain cross-signed to another trusted root (for
  example *AAA Certificate Services*) could in principle still validate. Some
  JDK vendors (Zulu) block the compromised intermediates by hash; others
  (Temurin) do not. The strip makes protection explicit and vendor-independent
  — do not assume a base is safe because one vendor blocks the intermediate.
* **Legitimate eMudhra ECC chains will fail.** Any upstream service whose
  certificate chains to *emSign ECC Root CA - G3* will start failing TLS from
  these images. That is intended: the root is considered compromised.
* **Running containers can regain the OS copy.** An in-place
  `ca-certificates` upgrade inside a running container restores OS trust until
  the next rebuild if the new package still ships the certificate. Rebuilt
  child images re-apply the strip every time.
* **External truststores are out of scope.** Stores your deployment imports
  itself (sidecars, operator-managed truststores, custom Java 8 images using
  `-keystore "$JAVA_HOME/jre/lib/security/cacerts"`) need their own treatment.

## Removing the mitigation

Remove the block once **all three** conditions hold:

1. Product patch releases ship JDKs whose truststores and blocklists exclude
   the compromised material;
2. the `images-base/*` images have been rebuilt from those releases; and
3. the `docker/` child images have been refreshed from them in the normal
   image cycle.

Before removing, rebuild a child image with the block deleted and confirm:
`keytool -list -cacerts -storepass changeit | grep -i emsign` shows no ECC G3
entry, the mozilla certificate file is absent, and both `dv-g3b` probe
endpoints fail.

## References

* [Cloudflare — eMudhra certificate compromise](https://blog.cloudflare.com/emudhra-certificate-compromise/)
* [BleepingComputer — Mozilla, Google, Apple block compromised eMudhra CA certificates](https://www.bleepingcomputer.com/news/security/mozilla-google-apple-block-compromised-emudhra-ca-certificates/)
* [FORGEOPS-6985 — tracking ticket](https://pingidentity.atlassian.net/browse/FORGEOPS-6985)

PingFederate and PingAccess ship in Ping product images on different bases and
are covered separately.
