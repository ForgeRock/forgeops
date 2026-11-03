# Alpine PingGateway child image (the two-step)

This is the Alpine sibling of [docker/ig](../../docker/ig): a child image that
derives from the IG team's published Alpine base image and re-applies the
ForgeOps customizations on top. Implements
[FORGEOPS-6995](https://pingidentity.atlassian.net/browse/FORGEOPS-6995).

## Why a second build path

The Debian line is a two-step too: the base Dockerfiles live upstream (the
PingGateway product repo publishes them to
`us-docker.pkg.dev/forgeops-public/images-base`), and `docker/ig` derives from
`images-base/ig` and re-applies the platform delta. The Alpine line needs the
same shape: the Alpine base image arrives from the shared platform pipeline
([FORGEOPS-4694](https://pingidentity.atlassian.net/browse/FORGEOPS-4694)),
and the ForgeOps delta (the config profile overlay) is layered here at build
time, exactly as `docker/ig` does for Debian.

The delta is the thinnest of the Alpine children: the published base already
carries the product install and its entrypoint, so the only layer is the
selected `config-profiles/<profile>/` overlay (plus the whole build context)
copied into `${IG_INSTANCE_DIR}` (the base's env — `/var/gateway`, expecting
`config/` and `scripts/` subfolders). The Debian child's other layer —
`COPY debian-buster-sources.list /etc/apt/sources.list`, the buster apt pin —
is Debian-specific and dropped: the Alpine base has no Debian apt. Two
profiles ship, same as Debian: `default` (platform) and `ig-only`
(standalone).

## The base image reference

The Dockerfile defaults to:

    ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/ig

**`latest` on that repo is the Debian build** (verified at the time of
writing: no Alpine tag published yet). The Alpine base is expected as a tag
dimension on the same repo, produced by the platform pipeline. Pin the base
with `--build-arg TAG=<alpine-tag>` or a release file; do not build against
`latest` until Alpine is published there. The build-time tell that the wrong
tag was pinned is the first `COPY --chown=${PING_USER}:${PING_GID}` failing
with an unresolved variable — the Debian image has no `PING_USER`/`PING_GID`
ENVs (the same contract as the DS child, `docker-alpine/ds`).

## Build

    bin/forgeops build -b docker-alpine -e <env> --push-to <registry> ig

`-b` points the build (and `forgeops image`, for release files) at this
directory instead of `docker/`; everything else — release files
(`docker-alpine/ig/releases/<name>`), the image-defaulter update, the helm
values update — works exactly as for the Debian child. To resolve this
directory from scripts, use
`bin/forgeops config path docker-alpine ig [profile]`.

## Keeping copies in sync

`config-profiles/` and `Dockerfile-custom` here are copies of `docker/ig`'s.
Update both together — with two deliberate exceptions on top of the apt-pin
drop:

* **`Dockerfile` is NOT a copy** of `docker/ig/Dockerfile`: it drops the
  buster apt pin and switches `COPY --chown` to `${PING_USER}:${PING_GID}`.
  Don't re-sync it from the Debian child.
* **`.gitignore` adds `/releases/`** (generated release files are
  build-time artifacts, never tracked — nothing under `releases/` is
  tracked anywhere in this repo; the base pin travels via
  `--build-arg TAG=`/CI, not a committed file).

`Dockerfile-custom` is a verbatim copy, with one inherited quirk documented
here because it is unreachable from the CLI on both lines (`forgeops config
build` accepts only `am` and `idm` as components): its
`COPY --chown=forgerock:root` runs against a `busybox:musl` base that has no
`forgerock` account, so the chown silently falls back to root (verified
empirically — the build succeeds and the files land root-owned; the same is
true of the Debian line's custom carrier today).

## See Also

* [Debian IG child image](../../docker/ig/Dockerfile) (no README — the Dockerfile is the contract)
* [Alpine DS child image](../ds/README.md)
* [Top-level forgeops README.md](../../README.md)
