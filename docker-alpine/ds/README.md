# Alpine PingDS child image (the two-step)

This is the Alpine sibling of [docker/ds](../../docker/ds): a child image that
derives from the DS team's published Alpine base image and re-applies the
ForgeOps customizations on top.

## Why a second build path

The Debian line is a two-step too: the base Dockerfiles live upstream (the
PingDS product repo publishes them to `us-docker.pkg.dev/forgeops-public/images-base`),
and `docker/ds` derives from `images-base/ds` and re-applies the platform
skeleton. The Alpine line needs the same shape for a different reason: the
ForgeOps runtime mode (PEM managers, relaxed policies, ldif-ext profile
enhancements, dual-mode runtime) is **our** delta, and the DS team is not
taking ForgeOps-mode changes into their published Alpine image. So we cannot
build the Alpine DS image purely upstream — the base arrives without the
platform skeleton, and this directory re-applies it, exactly as `docker/ds`
does for Debian.

The upstream Alpine image (single-mode skeleton: console loggers,
uid=admin/uid=monitor with passwords stripped, `data.tar.gz` PVC priming,
`instance.loc` -> `/opt/opendj/data`, PKCS12 keystore providers) ships from
the DS team's `opendj-docker-ds-alpine` module. Our delta on top is vendored
from the fork-internal branch `feature/pingds-alpine-dual-mode`
(paul-schroeder_pingcorp/opendj#1), which in turn vendors the pingds product
Dockerfile's final stage from the forgeops-docker-images build repo. In
other words: one source of truth (the product Dockerfile), three layers of
derivation — fork branch (adds the dual-mode scripts), this directory
(applies the ForgeOps skeleton to the published base).

## The base image reference

The Dockerfile defaults to:

    ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/ds

**`latest` on that repo is the Debian build.** The Alpine base is expected as
a tag dimension on the same repo (e.g. a release tag produced by an Alpine
variant of the base build). Pin the base with `--build-arg TAG=<alpine-tag>`
or a release file; do not build against `latest` until the DS team starts
publishing Alpine there — the tell that the wrong tag was pinned is a build
failure at the first `COPY --chown` (the Debian image has no `PING_USER` /
`PING_GID` ENVs).

## Runtime modes (the dual-mode contract)

One skeleton is baked at build time, always in the platform (forgeops)
layout: the instance root is `/opt/opendj/data` (`instance.loc` points
there), PEM Trust/Key Manager providers replace PKCS12, password policies
are relaxed, the AM/IDM setup profiles are enhanced from `ldif-ext/`, and
`data.tar.gz` primes a fresh PVC. `IMAGE_MODE` is a runtime selector only:

* `base` (default) — upstream samples/docker contract: keystore-based
  runtime, secrets under `secrets/`, opt-in admin/monitor password setting.
  The keystore is required in `/opt/opendj/secrets`, or set
  `USE_DEMO_KEYSTORE_AND_PASSWORDS=true`.
* `forgeops` — the k8s/PVC contract: passwords from
  `/var/run/secrets/opendj-passwords/`, PEM keys from the cert-manager
  secrets, per-pod runtime-scripts hooks. This is what the
  identity-platform chart uses (`platform.imageMode: forgeops`), and in
  chart deployments the chart's `ds-entrypoint` ConfigMap replaces the
  image's entrypoint wholesale — so the mode contract here mostly matters
  for standalone runs and for parity with the fork-internal image.

## Not shipped in this image

* **Runtime scripts** (`setup` / `post-init` / `add-schema`,
  `init-and-restore.sh`, ...) are NOT baked — same as the fork image. They
  are delivered at deploy time by the identity-platform chart's
  `ds-runtime-scripts` / `ds-<statefulset>-runtime-scripts` ConfigMaps
  (POSIX variants under `files-alpine/ds/runtime-scripts/`), mounted at
  `/opt/opendj/runtime-scripts`.
* **Debug tooling** — the Debian child installs `ncat`/`dnsutils`; the
  Alpine child installs nothing (busybox + wget cover the scripts). If you
  need extras, add an `apk --no-cache --update add ...` layer or an
  `ADDITIONAL_PACKAGES`-style ARG.

## Build

    bin/forgeops build -b docker-alpine -e <env> --push-to <registry> ds

`-b` points the build (and `forgeops image`, for release files) at this
directory instead of `docker/`; everything else — release files
(`docker-alpine/ds/releases/<name>`), the image-defaulter update, the helm
values update — works exactly as for the Debian child.

## Keeping copies in sync

* `ldif-ext/` and `config/schema/99-ext.ldif` here are copies of
  `docker/ds`'s (which are themselves identical to the fork branch's).
  Update all three together.
* `ds-setup.sh`, `docker-entrypoint.sh`, `env.sh` are vendored from the fork
  branch `feature/pingds-alpine-dual-mode`; if the fork image changes, mirror
  the change here (and vice versa: fixes found in this directory's context
  belong back in the fork branch).

## See Also

* [Debian DS child image](../../docker/ds/README.md)
* [Top-level forgeops README.md](../../README.md)
