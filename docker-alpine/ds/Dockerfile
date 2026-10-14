ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/ds
ARG TAG=latest

FROM ${REPO}:${TAG}

# The Alpine two-step child: derive from the DS team's published Alpine base
# (a tag dimension on the shared images-base/ds repo -- see README.md), then
# re-apply the ForgeOps delta that the upstream image does not carry: the
# platform skeleton (PEM managers, relaxed policies, ldif-ext profile
# enhancements, custom schema, data.tar.gz PVC priming) and the dual-mode
# runtime (IMAGE_MODE selector, base/forgeops contracts, PEM cert envs).
#
# Everything the child layers on comes from this directory; the scripts are
# vendored from our fork-internal opendj branch feature/pingds-alpine-dual-mode
# (paul-schroeder_pingcorp/opendj#1), which in turn vendors the pingds product
# Dockerfile's final stage from forgeops-docker-images.

# The base image finishes as ${PING_UID}:${PING_GID} (ping 9031:0 on
# published pingbase-java images). Those ENVs are the build-time tell that
# the pinned TAG is an Alpine pingbase-based build and not the Debian image:
# against the Debian tag the COPY --chown below fails with an unresolved
# variable. Take root briefly to guarantee /opt/opendj itself is ping-owned:
# early DS Alpine builds left the install root root-owned (docker creates a
# missing WORKDIR as root:root regardless of USER -- fixed in our fork
# branch, reported upstream), and the bake below deletes top-level entries.
# COPY --chown already owns the copied children, so a single chown suffices.
USER 0:0
RUN chown ${PING_USER}:${PING_GID} /opt/opendj

USER ${PING_UID}:${PING_GID}

# The PVC mount point where all writeable data is stored. The base sets this
# to /opt/opendj/data; restated here for clarity.
ENV DS_DATA_DIR /opt/opendj/data

# The PingDS deployment uses PEM based certificates. This sets the location
# of the certs. The base does not set these (its PKCS12 providers stay in
# place); our ds-setup.sh replaces them with the PEM managers and bakes these
# directories into the config. The standalone (non-chart) base-mode runtime
# provides real certs here or overrides the managers; harmless otherwise.
# This is set at docker *build* time. If you change this at runtime you must
# edit the config.ldif.
ENV PEM_KEYS_DIRECTORY "/var/run/secrets/keys/ds"
ENV PEM_TRUSTSTORE_DIRECTORY "/var/run/secrets/keys/truststore"

# IMAGE_MODE is a RUNTIME selector only (default "base", re-exported as ENV,
# overridable per container with -e IMAGE_MODE=...): base = upstream
# samples/docker contract, forgeops = the k8s/PVC contract. The identity
# platform chart sets the mode via platform.imageMode and its ds-entrypoint
# ConfigMap replaces this image's entrypoint wholesale. One skeleton is
# baked, always in the platform (forgeops) layout -- see ds-setup.sh.
ENV IMAGE_MODE=base

# Add the dual-mode runtime scripts that overlay the base's single-mode
# entrypoint, and the setup that re-bakes the skeleton.
COPY --chown=${PING_USER}:${PING_GID} docker-entrypoint.sh /opt/opendj/
COPY --chown=${PING_USER}:${PING_GID} docker-entrypoint-help.md /opt/opendj/
COPY --chown=${PING_USER}:${PING_GID} env.sh /opt/opendj/
COPY --chown=${PING_USER}:${PING_GID} ds-setup.sh /opt/opendj/

# Add custom schema files (consumed by the runtime setup scripts'
# custom-schema step; same files as the Debian child's config/schema).
COPY --chown=${PING_USER}:${PING_GID} config/schema/*.ldif /opt/opendj/custom-schema/

# Add custom ldap configuration (merged into the AM/IDM setup profiles by
# ds-setup.sh; deleted after setup to keep the image lean).
COPY --chown=${PING_USER}:${PING_GID} ldif-ext /opt/opendj/ldif-ext

# Re-bake the skeleton. The base already baked its own single-mode instance:
# remove data/ (the instance), data.tar.gz (its PVC prime tar) and
# instance.loc (the pointer setup recreates) before our setup runs. The
# server template/ tree MUST be kept -- ./setup copies the instance skeleton
# from it, and the samples/docker/template stub inside ds-setup.sh only
# merges the audit-handlers/tools.properties additions (cp -r into an
# existing directory merges, it does not nest). Then bake the
# platform-layout skeleton with all of the platform extensions (see
# ds-setup.sh) and drop the setup script and the ldif-ext assets it consumed.
RUN cd /opt/opendj && rm -rf data data.tar.gz instance.loc \
        && ./ds-setup.sh && rm ./ds-setup.sh && rm -fr ldif-ext

# The base's ENTRYPOINT already points at /opt/opendj/docker-entrypoint.sh;
# re-declared so the contract survives the file overlay even if the base
# ever moves the path.
ENTRYPOINT ["/opt/opendj/docker-entrypoint.sh"]
