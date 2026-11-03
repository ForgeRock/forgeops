ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/ig
ARG TAG=latest

FROM ${REPO}:${TAG}

# The Alpine two-step child: derive from the IG team's published Alpine base
# (a tag dimension on the shared images-base/ig repo -- see README.md), then
# re-apply the ForgeOps delta from docker/ig. The delta is only the config
# profile overlay: the Debian child's other layer (the
# debian-buster-sources.list apt pin) is Debian-specific and dropped -- the
# Alpine base has no Debian apt.
#
# The base's PING_USER/PING_GID ENVs are the build-time tell that
# the pinned TAG is an Alpine pingbase-based build and not the Debian image:
# against the Debian tag the COPY --chown below fails with an unresolved
# variable (latest on images-base/ig is the Debian build today).
# ${IG_INSTANCE_DIR} likewise comes from the base (its env contract); an
# empty expansion makes the COPY a one-argument instruction and the build
# aborts loudly.

# Copy all config files into the docker image.
# The default ig directory is /var/gateway (IG_INSTANCE_DIR env var from the
# base), and it expects subfolders config/ and scripts/ (if required)
ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=${PING_USER}:${PING_GID} config-profiles/${CONFIG_PROFILE}/ ${IG_INSTANCE_DIR}
COPY --chown=${PING_USER}:${PING_GID} . ${IG_INSTANCE_DIR}
