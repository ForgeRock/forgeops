# Alpine am-config-upgrader child image (the two-step)

This is the Alpine sibling of
[docker/am-config-upgrader](../../docker/am-config-upgrader): a child image
that derives from the AM team's published Alpine base image. Implements
[FORGEOPS-7007](https://pingidentity.atlassian.net/browse/FORGEOPS-7007).

## Why a second build path, and why the delta is empty

The Debian line is a two-step: the base Dockerfiles live upstream (published
to `us-docker.pkg.dev/forgeops-public/images-base`), and
`docker/am-config-upgrader` derives from `images-base/am-config-upgrader`.
The Debian child's entire delta is `chown 11111:11111 /home/forgerock` — the
Debian base lands its home root-owned.

The Alpine pingbase chain does not have that problem: the base lands
`/home/forgerock` forgerock-owned (`PING_USER`/`PING_UID`/`PING_GID`,
verified against the pingbase alpine images — uid 11111, home writable). So
per the ticket ("verify how the Alpine base lands its ownership and reduce
the delta accordingly"), **the ForgeOps delta here is empty by design**: the
directory exists to give the alpine line a build path (`forgeops build -b
docker-alpine am-config-upgrader`, release files, `set-images`/`config
path` resolution) and to carry the wrong-pin tell.

## The wrong-pin tell

The other children fail loudly on a Debian tag at their first
`COPY --chown=${PING_USER}` (unresolved variable). This Dockerfile has no
COPY, so the ownership `RUN` stands in: it passes on any Alpine
pingbase-based base and **fails on the Debian tag** (whose home is
root-owned until the Debian child's chown). `latest` on
`images-base/am-config-upgrader` is the Debian build today (verified at the
time of writing: no Alpine tag published yet) — pin the Alpine tag with
`--build-arg TAG=<alpine-tag>` or a release file.

## Build

    bin/forgeops build -b docker-alpine -e <env> --push-to <registry> am-config-upgrader

`-b` points the build (and `forgeops image`, for release files) at this
directory instead of `docker/`; everything else — release files, the
image-defaulter update, the helm values update — works exactly as for the
Debian child. To resolve this directory from scripts, use
`bin/forgeops config path docker-alpine am-config-upgrader`.

## Keeping copies in sync

Nothing to sync: this directory carries no copies of `docker/am-config-upgrader`'s
files — the Debian child has only its Dockerfile, whose entire delta (the
chown) is deliberately not reproduced here (see above).

## See Also

* [Debian am-config-upgrader child image](../../docker/am-config-upgrader/Dockerfile)
* [Alpine DS child image](../ds/README.md)
* [Top-level forgeops README.md](../../README.md)
