# Alpine PingIDM child image (the two-step)

This is the Alpine sibling of [docker/idm](../../docker/idm): a child image that
derives from the IDM team's published Alpine base image and re-applies the
ForgeOps customizations on top. Implements
[FORGEOPS-6994](https://pingidentity.atlassian.net/browse/FORGEOPS-6994).

## Why a second build path

The Debian line is a two-step too: the base Dockerfiles live upstream (the
PingIDM product repo publishes them to
`us-docker.pkg.dev/forgeops-public/images-base`), and `docker/idm` derives from
`images-base/idm` and re-applies the platform delta. The Alpine line needs the
same shape: the Alpine base image arrives from the shared platform pipeline
([FORGEOPS-4694](https://pingidentity.atlassian.net/browse/FORGEOPS-4694)),
and the ForgeOps delta (config profile, resolver bootstrap, PEM truststore
import, Felix hardening, JVM options) is layered here at build time, exactly
as `docker/idm` does for Debian.

The delta is thinner than the DS child's: the published base already carries
the product install, so nothing is re-baked. What this directory layers on:

* the Felix OSGI console jars are removed (the Debian child's hardening)
* `JAVA_OPTS` restated (the cgroup-RAM percentages workaround, OPENIDM-16100)
* the selected `config-profiles/<profile>/` overlay plus the whole build
  context (`bin/import-pem-certs.sh`, `resolver/boot.properties`) copied into
  `/opt/openidm`
* nothing is installed: the Debian child's `apt-get install openssl` layer is
  dropped — no script in this build context uses the openssl CLI
  (`import-pem-certs.sh` uses `keytool` only, which ships with the JVM) — and
  the Alpine base carries no Debian apt to point at `debian-buster-sources.list`
  (that file in `docker/idm/` is itself unreferenced copy-paste legacy from
  `docker/ig/`).

## The base image reference

The Dockerfile defaults to:

    ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/idm

**`latest` on that repo is the Debian build** (verified at the time of
writing: no Alpine tag published yet). The Alpine base is expected as a tag
dimension on the same repo, produced by the platform pipeline. Pin the base
with `--build-arg TAG=<alpine-tag>` or a release file; do not build against
`latest` until Alpine is published there. The build-time tell that the wrong
tag was pinned is the first `COPY --chown=${PING_USER}:${PING_GID}` failing
with an unresolved variable — the Debian image has no `PING_USER`/`PING_GID`
ENVs (the same contract as the DS child, `docker-alpine/ds`).

## Build

    bin/forgeops build -b docker-alpine -e <env> --push-to <registry> idm

`-b` points the build (and `forgeops image`, for release files) at this
directory instead of `docker/`; everything else — release files
(`docker-alpine/idm/releases/<name>`), the image-defaulter update, the helm
values update — works exactly as for the Debian child. To resolve this
directory from scripts, use
`bin/forgeops config path docker-alpine idm [profile]`.

## Keeping copies in sync

`bin/import-pem-certs.sh`, `config-profiles/default/`,
`resolver/boot.properties`, `connectors/` and `Dockerfile-custom` here are
copies of `docker/idm`'s. Update both together (the script itself is already
written to be shared by the Debian and Alpine image lines — it takes the CA
bundle path from the environment, and the chart sets the Alpine path per
image line). `Dockerfile-custom` cannot be synced independently of
`connectors/`: its `COPY *connectors/` globs on that directory (empty in git,
kept by `.gitkeep` — the exported IDM connector jars land there at deploy
time), so a build of the custom-config carrier fails if the directory is
absent.

## See Also

* [Debian IDM child image](../../docker/idm/Dockerfile) (no README — the Dockerfile is the contract)
* [Alpine DS child image](../ds/README.md)
* [Top-level forgeops README.md](../../README.md)
