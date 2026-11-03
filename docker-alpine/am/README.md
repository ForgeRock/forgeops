# Alpine PingAM child image (the two-step)

This is the Alpine sibling of [docker/am](../../docker/am): a child image that
derives from the AM team's published Alpine base image and re-applies the
ForgeOps customizations on top. Implements
[FORGEOPS-6993](https://pingidentity.atlassian.net/browse/FORGEOPS-6993).

## Why a second build path

The Debian line is a two-step too: the base Dockerfiles live upstream (the
PingAM product repo publishes them to
`us-docker.pkg.dev/forgeops-public/images-base`), and `docker/am` derives from
`images-base/am` and re-applies the platform delta. The Alpine line needs the
same shape: the Alpine base image arrives from the shared platform pipeline
([FORGEOPS-4694](https://pingidentity.atlassian.net/browse/FORGEOPS-4694)),
and the ForgeOps delta is layered here at build time, exactly as `docker/am`
does for Debian.

What this directory layers on:

* the selected `config-profiles/<profile>/` overlay into
  `/home/forgerock/openam/` (the chart's `platform.amHome` is a constant
  `/home/forgerock`; the Alpine pingbase chain sets `PING_HOME=/home/forgerock`
  too) plus the whole build context — `export.sh` and `import-pem-certs.sh`
  (the latter is already written to be shared by the Debian and Alpine image
  lines; the chart mounts it over the image copy per image line)
* `/home/forgerock/logging/` (the logback drop-in directory the base's
  `CATALINA_OPTS` points at)
* the SecurID auth-module workaround (FORGEOPS-6642; remove after the next
  Maj/Min release per the Debian child's comment)
* `ENV CATALINA_OPTS` re-statement of the logback flag (idempotent append,
  matching the Debian child)

Dropped from the Debian child: the `apt-get install jq` layer — nothing in
this build context or the chart's AM templates invokes the jq CLI. The
Alpine base has no Debian apt.

## The base image reference

The Dockerfile defaults to:

    ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/am

**`latest` on that repo is the Debian build** (verified at the time of
writing: no Alpine tag published yet). The Alpine base is expected as a tag
dimension on the same repo, produced by the platform pipeline. Pin the base
with `--build-arg TAG=<alpine-tag>` or a release file; do not build against
`latest` until Alpine is published there. The build-time tell that the wrong
tag was pinned is the first `COPY --chown=${PING_USER}:${PING_GID}` failing
with an unresolved variable — the Debian image has no `PING_USER`/`PING_GID`
ENVs (the same contract as the DS child, `docker-alpine/ds`).

## Build

    bin/forgeops build -b docker-alpine -e <env> --push-to <registry> am

`-b` points the build (and `forgeops image`, for release files) at this
directory instead of `docker/`; everything else — release files
(`docker-alpine/am/releases/<name>`), the image-defaulter update, the helm
values update — works exactly as for the Debian child. To resolve this
directory from scripts, use
`bin/forgeops config path docker-alpine am [profile]`.

## Keeping copies in sync

`config-profiles/`, `export.sh`, `import-pem-certs.sh` and
`Dockerfile-custom` here are copies of `docker/am`'s. Update both together.
**`Dockerfile` is NOT a copy**: it drops the jq apt layer and switches
`COPY --chown` to `${PING_USER}:${PING_GID}`. Don't re-sync it from the
Debian child.

## See Also

* [Debian AM child image](../../docker/am/Dockerfile) (no README — the Dockerfile is the contract)
* [Alpine DS child image](../ds/README.md)
* [Top-level forgeops README.md](../../README.md)
