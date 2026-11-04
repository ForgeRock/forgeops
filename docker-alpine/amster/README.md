# Alpine amster child image (the two-step)

This is the Alpine sibling of [docker/amster](../../docker/amster): a child
image that derives from the AM team's published Alpine base image and
re-applies the ForgeOps customizations on top. Implements
[FORGEOPS-7006](https://pingidentity.atlassian.net/browse/FORGEOPS-7006).

## Why a second build path

The Debian line is a two-step too: the base Dockerfiles live upstream (the
PingAM product repo publishes them to
`us-docker.pkg.dev/forgeops-public/images-base`), and `docker/amster`
derives from `images-base/amster` and re-applies the platform delta. The
Alpine line needs the same shape: the Alpine base image arrives from the
shared platform pipeline
([FORGEOPS-4694](https://pingidentity.atlassian.net/browse/FORGEOPS-4694)),
and the ForgeOps delta (the config-profile overlay, the runtime scripts and
the import-upload job file) is layered here at build time, exactly as
`docker/amster` does for Debian.

What this directory layers on:

* the selected `config-profiles/<profile>/` overlay into `/opt/amster`
  (both profiles ship, same as Debian: `default` and `am-only`) plus the
  `scripts/` runtime tree (`docker-entrypoint.sh`, `import.sh`,
  `export.sh` — POSIX sh, written for both image lines since the
  FORGEOPS-6971 script-tree merge)
* `ENV SERVER_URI=/am` restated (matching the Debian child)
* `chmod 777 /opt/amster` (amster wants to create a preferences directory)

`amster-scripts/import-upload.amster` is carried in this directory (verbatim
from `docker/amster`) but NOT copied into the image — the Debian
Dockerfile doesn't COPY it either, and no chart or script in the repo
references it (it came from the 7.0 migration as dead weight).

Dropped from the Debian child: the whole apt layer. Of its three packages
only `wget` is invoked (the scripts' alive checks), and the Alpine pingbase
base already ships busybox wget, which supports the exact flags the scripts
use (`--server-response --tries=1`, verified against the pingbase alpine
chain). `jq` and `openldap-utils` have no consumer in this build context or
the chart's amster templates — the chart's jq consumers
(`keystore-create.sh`, `ds-set-passwords`) run on the AM and DS images, not
amster. `DEBIAN_FRONTEND`/`APT_OPTS` were apt-only envs, and the
`USER root` → `USER forgerock` bracket went with them: the runtime uid here
comes entirely from the base, as in the idm/ig/am children.

## The base image reference

The Dockerfile defaults to:

    ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/amster

**`latest` on that repo is the Debian build** (verified at the time of
writing: no Alpine tag published yet). The Alpine base is expected as a tag
dimension on the same repo, produced by the platform pipeline. Pin the base
with `--build-arg TAG=<alpine-tag>` or a release file; do not build against
`latest` until Alpine is published there. The build-time tell that the wrong
tag was pinned is the first `COPY --chown=${PING_USER}:${PING_GID}` failing
with an unresolved variable — the Debian image has no `PING_USER`/`PING_GID`
ENVs (the same contract as the ds/idm/ig/am children).

## Build

    bin/forgeops build -b docker-alpine -e <env> --push-to <registry> amster

`-b` points the build (and `forgeops image`, for release files) at this
directory instead of `docker/`; everything else — release files
(`docker-alpine/amster/releases/<name>`), the image-defaulter update, the
helm values update — works exactly as for the Debian child. To resolve this
directory from scripts, use
`bin/forgeops config path docker-alpine amster [profile]`.

## Keeping copies in sync

`config-profiles/`, `scripts/`, `amster-scripts/` and `.gitignore` here are
copies of `docker/amster`'s (`.gitignore` adds `/releases/` — generated
release files are build-time artifacts, never tracked; see the ig child
README). **`Dockerfile` is NOT a copy**: it drops the apt layer (and its
envs and USER bracket) and switches `COPY --chown` to
`${PING_USER}:${PING_GID}`. Don't re-sync it from the Debian child.

## See Also

* [Debian amster child image](../../docker/amster/Dockerfile) (no README — the Dockerfile is the contract)
* [Alpine DS child image](../ds/README.md)
* [Top-level forgeops README.md](../../README.md)
