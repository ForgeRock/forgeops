ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/idm
ARG TAG=latest

FROM ${REPO}:${TAG}

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
        apt-get install -y --no-install-recommends openssl && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*
USER 11111

# Harden PingIDM by removing the Felix OSGI Console. Unless you are a ForgeRock developer, the
# console is rarely required. Your configuration should NOT include conf/felix.webconsole.json
RUN rm -f bundle/org.apache.felix.webconsole*.jar  && \
    rm -f bundle/openidm-felix-webconsole-*.jar

# Remove this once https://bugster.forgerock.org/jira/browse/OPENIDM-16100 is integrated
# This sets the RAM based on cgroups to 65% of the container memory.
# The trailing -XX:-UseBASE64Intrinsics mitigates CVE-2026-114938 (Java4Shell,
# FORGEOPS-7044) while the base image's JDK predates the November 2026 fix
# (21.0.13.1+ on the 21 line). No security benefit on ARM64 or on x86-64
# without AVX-512 (the vulnerable path is the AVX-512 Base64 intrinsic), and
# there the flag costs some Base64 throughput. Remove the flag once the base
# image ships a patched JDK. A runtime JAVA_OPTS override replaces this
# whole ENV -- include the flag there too.
ENV JAVA_OPTS -XX:MaxRAMPercentage=65 -XX:InitialRAMPercentage=65 -XX:MaxTenuringThreshold=1 -Djava.security.egd=file:/dev/urandom -XshowSettings:vm  -XX:+PrintFlagsFinal -XX:-UseBASE64Intrinsics

ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /opt/openidm
COPY --chown=forgerock:root . /opt/openidm
