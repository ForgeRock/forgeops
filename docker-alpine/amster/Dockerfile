ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/amster
ARG TAG=latest

FROM ${REPO}:${TAG}

# The Alpine two-step child: derive from the AM team's published Alpine base
# (a tag dimension on the shared images-base/amster repo -- see README.md),
# then re-apply the ForgeOps delta from docker/amster: the config-profile
# overlay, the runtime scripts (POSIX, shared by both image lines) and the
# amster import-upload job file.
#
# The Debian child's apt layer is dropped: of its three packages only wget
# is actually invoked (the scripts' alive checks), and the Alpine pingbase
# base already ships busybox wget, which supports the exact flags the
# scripts use (--server-response --tries, verified). jq and openldap-utils
# have no consumer in this build context or the chart's amster templates
# (the chart's jq consumers -- keystore-create.sh, ds-set-passwords -- run
# on the AM and DS images, not amster). DEBIAN_FRONTEND / APT_OPTS were
# apt-only envs; the USER root -> USER forgerock bracket went with them, so
# the runtime uid comes entirely from the base (as in the idm/ig/am
# children).
#
# The base's PING_USER/PING_GID ENVs are the build-time tell that the pinned
# TAG is an Alpine pingbase-based build and not the Debian image: against the
# Debian tag the COPY --chown below fails with an unresolved variable
# (latest on images-base/amster is the Debian build today).

ENV SERVER_URI /am

ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=${PING_USER}:${PING_GID} config-profiles/${CONFIG_PROFILE}/ /opt/amster
COPY --chown=${PING_USER}:${PING_GID} scripts /opt/amster
# This is needed to make amster happy. It wants to create a preferences directory
RUN chmod 777 /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
