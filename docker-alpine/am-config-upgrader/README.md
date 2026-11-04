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
`/home/forgerock` forgerock-owned. Verified against our CI's pingbase-based
alpine images (`us-docker.pkg.dev/forgeops-public/images/alpine/{am,amster,idm,ig}`:
`PING_UID=11111` exported as an ENV, `/home/forgerock` owned by uid 11111 and
writable by it). So per the ticket ("verify how the Alpine base lands its
ownership and reduce the delta accordingly"), **the ForgeOps delta here is
empty by design**: the directory exists to give the alpine line a build path
(`forgeops build -b docker-alpine am-config-upgrader`; release files via
`forgeops image`, whose COMPONENTS_APPS covers this component; consumed by
`forgeops upgrade-am-config`) and to carry the wrong-pin tell. Note
`bin/set-images --products` and `forgeops config path` do NOT list this
component on the Debian line either — this child mirrors that status quo
rather than widening the component lists.

## The wrong-pin tell

The other children fail loudly on a Debian tag at their first use of the
base's `PING_*` variables — for most a `COPY --chown=${PING_USER}` with an
unresolved variable, for the ds and am children a `USER`/`RUN chown` line
that reaches them even earlier. This Dockerfile has no COPY, so the
ownership assert in the Dockerfile stands in, hardened against the vacuous
pass a naive `[ "$(stat ...)" = "${PING_UID}" ]` would produce (both sides
empty on a base that exports no `PING_UID` and has no home): an unset or
empty `PING_UID` aborts the build with an explanatory error, a missing
`/home/forgerock` fails the `stat`, and only a base that exports `PING_UID`
AND lands the home owned by that same uid passes. The assert is
base-relative — whatever uid the platform's Alpine base bakes, home and
`PING_UID` must agree. `latest` on `images-base/am-config-upgrader` is the
Debian build today (verified at the time of writing: no Alpine tag
published yet) — pin the Alpine tag with `--build-arg TAG=<alpine-tag>` or a
release file.

## Build

    bin/forgeops build -b docker-alpine -e <env> --push-to <registry> am-config-upgrader

`-b` (a `forgeops build`/`forgeops image` flag) points the build — and
release-file generation — at this directory instead of `docker/`. Unlike the
ds/am/idm/ig/amster children, `forgeops config path` cannot resolve this
directory: `am-config-upgrader` is absent from its component choices on the
Debian line too (pre-existing; same for `set-images --products`).

## Keeping copies in sync

Nothing to sync: this directory carries no copies of `docker/am-config-upgrader`'s
files — the Debian child has only its Dockerfile, whose entire delta (the
chown) is deliberately not reproduced here (see above). The `.gitignore`
(the only file besides the Dockerfile and this README) ignores
`/releases/`: build-time-generated release files (`bin/commands/image` and
`bin/commands/upgrade-am-config` write under it), never tracked — the
Debian directory has no `.gitignore` of its own.

## See Also

* [Debian am-config-upgrader child image](../../docker/am-config-upgrader/Dockerfile)
* [Alpine DS child image](../ds/README.md)
* [Top-level forgeops README.md](../../README.md)
