ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/amster
ARG TAG=latest

FROM ${REPO}:${TAG}

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_OPTS="--no-install-recommends --yes"
# inotify-tools was installed for the old import.sh upload-wait mode
# (wait_config_file_upload); the scripts no longer use inotifywait, so the
# package is dropped. (FORGEOPS-6971 script-tree merge, 2026-10.)
RUN apt-get update \
        && apt-get install -y openldap-utils jq wget \
        && apt-get clean \
        && rm -r /var/lib/apt/lists /var/cache/apt/archives

# To be removed in future release
# RUN apt-get remove -y curl

USER forgerock

# CVE-2026-114938 (Java4Shell, FORGEOPS-7044): the base image's JDK predates
# the November 2026 fix (25.0.5.1+ on the 25 line), so disable the
# AVX-512-accelerated java.util.Base64 intrinsics until the base is rebuilt.
# No security benefit on ARM64 or on x86-64 without AVX-512 (the
# vulnerable path is the AVX-512 Base64 intrinsic), and there the flag
# costs some Base64 throughput; remove once the base image ships a patched
# JDK. JDK_JAVA_OPTIONS is consumed by the JDK 9+ java
# launcher itself -- the amster launcher script execs `java` bare, reading no
# opts variable of its own; JDK_JAVA_OPTIONS prints a "NOTE:" line on
# startup, which is expected.
ENV JDK_JAVA_OPTIONS=-XX:-UseBASE64Intrinsics

ENV SERVER_URI /am

ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /opt/amster
COPY --chown=forgerock:root scripts /opt/amster
# This is needed to make amster happy. It wants to create a preferences directory
RUN chmod 777 /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
