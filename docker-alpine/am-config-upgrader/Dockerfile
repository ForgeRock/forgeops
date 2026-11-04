ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/am-config-upgrader
ARG TAG=latest

FROM ${REPO}:${TAG}

# The Alpine two-step child: derive from the AM team's published Alpine base
# (a tag dimension on the shared images-base/am-config-upgrader repo -- see
# README.md). The ForgeOps delta is EMPTY by design: the Debian child exists
# only to chown /home/forgerock (the Debian base leaves it root-owned); the
# Alpine pingbase chain already lands the home forgerock-owned (PING_USER/
# PING_UID/PING_GID; verified against our CI's pingbase alpine images --
# alpine/{am,amster,idm,ig}, all PING_UID=11111, home owned by 11111 and
# writable), so there is nothing to re-apply.
#
# What remains is the wrong-pin tell. The other children fail loudly on a
# Debian tag at their first use of the base's PING_* variables (a COPY
# --chown with an unresolved variable, or a USER chown); this Dockerfile has
# no COPY, so the assert below stands in. Unlike a COPY --chown (expanded and
# validated by docker), a RUN expands ${PING_UID} through the shell, which
# would substitute the empty string silently -- so the assert guards on both
# halves: an unset/empty PING_UID aborts the RUN (a base that does not export
# PING_UID is not a pingbase descendant), and a missing /home/forgerock fails
# the stat. Only a base that exports PING_UID AND lands the home owned by
# that same uid passes. The assert is base-relative: whatever uid the
# platform's Alpine base bakes, home and PING_UID must agree. Verified: green
# against a pingbase alpine stand-in, and failing with the explanatory
# message against the real Debian base (images-base/am-config-upgrader
# 7.4.2: no PING_UID, home root-owned) and against plain alpine (neither).
# latest on images-base/am-config-upgrader is the Debian build today -- pin
# the Alpine tag via a release file or --build-arg TAG=.
RUN set -eu; \
    uid="${PING_UID:?ERROR: the base does not export PING_UID -- the pinned TAG is probably not an Alpine pingbase-based build}"; \
    home_uid="$(stat -c %u /home/forgerock)"; \
    [ "$home_uid" = "$uid" ] \
        || { echo "ERROR: /home/forgerock is owned by uid $home_uid, not the base's PING_UID ($uid) -- the pinned TAG is probably the Debian build, not an Alpine pingbase-based one" >&2; exit 1; }
