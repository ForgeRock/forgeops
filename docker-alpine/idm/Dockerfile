ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/idm
ARG TAG=latest

FROM ${REPO}:${TAG}

# The Alpine two-step child: derive from the IDM team's published Alpine base
# (a tag dimension on the shared images-base/idm repo -- see README.md), then
# re-apply the ForgeOps delta from docker/idm. Unlike the DS child there is no
# skeleton to re-bake: the published base already carries the product install,
# so the delta is the Debian child's minus its apt layer -- the openssl
# package it installed is referenced by no script in this build context
# (bin/import-pem-certs.sh uses keytool only, which ships with the JVM).
#
# The base's PING_USER/PING_UID/PING_GID ENVs are the build-time tell that
# the pinned TAG is an Alpine pingbase-based build and not the Debian image:
# against the Debian tag the COPY --chown below fails with an unresolved
# variable (latest on images-base/idm is the Debian build today).

# Harden PingIDM by removing the Felix OSGI Console. Unless you are a ForgeRock developer, the
# console is rarely required. Your configuration should NOT include conf/felix.webconsole.json
RUN rm -f bundle/org.apache.felix.webconsole*.jar  && \
    rm -f bundle/openidm-felix-webconsole-*.jar

# Remove this once https://bugster.forgerock.org/jira/browse/OPENIDM-16100 is integrated
# This sets the RAM based on cgroups to 65% of the container memory
ENV JAVA_OPTS -XX:MaxRAMPercentage=65 -XX:InitialRAMPercentage=65 -XX:MaxTenuringThreshold=1 -Djava.security.egd=file:/dev/urandom -XshowSettings:vm  -XX:+PrintFlagsFinal

ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=${PING_USER}:${PING_GID} config-profiles/${CONFIG_PROFILE}/ /opt/openidm
COPY --chown=${PING_USER}:${PING_GID} . /opt/openidm
