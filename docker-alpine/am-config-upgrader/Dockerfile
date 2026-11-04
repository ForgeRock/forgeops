ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/am-config-upgrader
ARG TAG=latest

FROM ${REPO}:${TAG}

# The Alpine two-step child: derive from the AM team's published Alpine base
# (a tag dimension on the shared images-base/am-config-upgrader repo -- see
# README.md). The ForgeOps delta is EMPTY by design: the Debian child exists
# only to chown /home/forgerock (the Debian base leaves it root-owned); the
# Alpine pingbase chain already lands the home forgerock-owned (PING_USER/
# PING_UID/PING_GID, verified against the pingbase alpine images), so there
# is nothing to re-apply.
#
# What remains is the wrong-pin tell. The other children fail loudly on a
# Debian tag at their first COPY --chown=${PING_USER} (unresolved variable);
# this Dockerfile has no COPY, so the ownership assert below stands in: it
# passes on any Alpine pingbase-based base (whose home is forgerock-owned)
# and FAILS on the Debian tag (whose home is root-owned until the Debian
# child's chown). latest on images-base/am-config-upgrader is the Debian
# build today -- pin the Alpine tag via a release file or --build-arg TAG=.
RUN [ "$(stat -c %u /home/forgerock)" = "${PING_UID}" ] \
        || { echo "ERROR: /home/forgerock is not owned by the base's PING_UID (${PING_UID}) -- the pinned TAG is probably the Debian build, not an Alpine pingbase-based one" >&2; exit 1; }
