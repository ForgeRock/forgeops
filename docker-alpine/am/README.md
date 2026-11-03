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

* `jq` via apk (the Debian child installs it via apt): the chart's
  keystore-create job runs `files/keystore/keystore-create.sh` on the AM
  image (its `initImage` resolves via `platform.imageRef "am"`), and that
  script parses `keystore.json` with jq under `set -e` — in forgeops image
  mode the deployer re-points `platform.imageRepository` at the alpine line
  and this job follows, so the alpine AM image must carry jq on PATH just
  like the Debian one
* the selected `config-profiles/<profile>/` overlay into
  `/home/forgerock/openam/` (the chart's `platform.amHome` is a constant
  `/home/forgerock`; the Alpine pingbase chain sets `PING_HOME=/home/forgerock`
  too) plus the two helper scripts (`COPY *.sh`) — `export.sh` and
  `import-pem-certs.sh` (the latter is written to be shared by the Debian and
  Alpine image lines; the chart mounts its one POSIX tree over the image copy
  identically for both lines since FORGEOPS-6971)
* `/home/forgerock/logging/` (the logback drop-in directory the Dockerfile's
  `CATALINA_OPTS` line points at)
* the SecurID auth-module workaround (FORGEOPS-6642; remove after the next
  Maj/Min release per the Debian child's comment)
* `ENV CATALINA_OPTS` re-statement of the logback flag (an append matching
  the Debian child; the base does not set the flag itself)

The Debian child's `apt-get install jq` becomes the apk layer above; its
`USER root` → `USER 11111` bracket (an apt artifact) is dropped — the runtime
uid here comes entirely from the base, as in the idm/ig children.

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

`config-profiles/`, `import-pem-certs.sh` and `Dockerfile-custom` here are
copies of `docker/am`'s. Update both together.
**`Dockerfile` is NOT a copy**: it installs jq via apk (the Debian line via
apt), drops the `USER root` → `USER 11111` apt bracket, and switches
`COPY --chown` to `${PING_USER}:${PING_GID}`. Don't re-sync it from the
Debian child.
**`export.sh` differs in one line**: its shebang is `#!/bin/sh` here
(the Alpine base has no bash; the script body is fully POSIX and runs
under busybox ash, verified) — the Debian copy keeps
`#!/usr/bin/env bash`. Re-syncing it from the Debian child must keep the
shebang flip, or `kubectl exec am-pod -- export.sh -` fails on this
image line.
**`.gitignore` adds `/releases/`** over `docker/am`'s (generated release
files are build-time artifacts, never tracked — see the ig child README).

**`Dockerfile-custom` quirk inherited from the Debian copy**: its
`COPY --chown=forgerock:root` runs against a `busybox:musl` base that has no
`forgerock` account, so the chown silently falls back to root (verified
empirically; the same is true of the Debian line's carrier). Unlike the ig
child's unreachable copy, `forgeops config build` ACCEPTS `am` as a
component, so this file is reachable from the CLI on this line — if the
chown ever matters, fix it on both lines in the same commit.

## See Also

* [Debian AM child image](../../docker/am/Dockerfile) (no README — the Dockerfile is the contract)
* [Alpine DS child image](../ds/README.md)
* [Top-level forgeops README.md](../../README.md)
