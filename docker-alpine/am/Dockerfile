ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/am
ARG TAG=latest

FROM ${REPO}:${TAG}

# The Alpine two-step child: derive from the AM team's published Alpine base
# (a tag dimension on the shared images-base/am repo -- see README.md), then
# re-apply the ForgeOps delta from docker/am. The base carries the product
# install and its Tomcat runtime; the delta is the config-profile overlay,
# the two helper scripts, the logging directory, the SecurID auth-module
# workaround and the logback CATALINA_OPTS re-statement.
#
# The Debian child's apt layer (jq) is dropped: nothing in this build context
# or the chart's AM templates invokes the jq CLI (grep-verified against
# export.sh/import-pem-certs.sh and charts/identity-platform); if a future
# script needs it, it returns as an `apk add jq` layer.
#
# The base's PING_USER/PING_GID ENVs are the build-time tell that the pinned
# TAG is an Alpine pingbase-based build and not the Debian image: against the
# Debian tag the COPY --chown below fails with an unresolved variable
# (latest on images-base/am is the Debian build today). The home directory
# stays hardcoded at /home/forgerock (matching docker/am and the chart's
# platform.amHome helper, which is a constant); the Alpine pingbase chain
# sets PING_HOME=/home/forgerock too.

ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=${PING_USER}:${PING_GID} config-profiles/${CONFIG_PROFILE}/ /home/forgerock/openam/

COPY --chown=${PING_USER}:${PING_GID} *.sh /home/forgerock/

RUN mkdir -p /home/forgerock/logging

# Workaround for 8.1.0 to add missing SecurID auth module to amauthservice. This should be removed once the fix is in place in the base image.
# Remove workaround after the next Maj/Min release: FORGEOPS-6642
RUN if [ -f /home/forgerock/openam/config/services/realm/root/iplanetamauthservice/1.0/globalconfig/default.json ]; then \
        if ! grep -q "com.sun.identity.authentication.modules.securid.SecurID" /home/forgerock/openam/config/services/realm/root/iplanetamauthservice/1.0/globalconfig/default.json; then \
            sed -i -e 's/\"com.sun.identity.authentication.modules.sae.SAE\",/\"com.sun.identity.authentication.modules.sae.SAE\",\n      \"com.sun.identity.authentication.modules.securid.SecurID\",/' /home/forgerock/openam/config/services/realm/root/iplanetamauthservice/1.0/globalconfig/default.json; \
        fi \
    fi


ENV CATALINA_OPTS="${CATALINA_OPTS} -Dlogback.configurationFile=/home/forgerock/logging/logback.xml"

WORKDIR /home/forgerock

# If you want to debug PingAM uncomment these lines:
#ENV JPDA_TRANSPORT=dt_socket
#ENV JPDA_ADDRESS *:9009
