ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/ds
ARG TAG=latest

FROM ${REPO}:${TAG}

# FOR DEBUG. Remove for production deployment
USER root
RUN apt-get update && apt-get install -y --no-install-recommends ncat dnsutils 
USER forgerock

# The PVC mount point where all writeable data is stored.
ENV DS_DATA_DIR /opt/opendj/data

# CVE-2026-114938 (Java4Shell, FORGEOPS-7044): the base image's JDK predates
# the November 2026 fix (25.0.5.1+ on the 25 line), so disable the
# AVX-512-accelerated java.util.Base64 intrinsics until the base is rebuilt.
# No security benefit on ARM64 or on x86-64 without AVX-512 (the
# vulnerable path is the AVX-512 Base64 intrinsic), and there the flag
# costs some Base64 throughput; remove once the base image ships a patched
# JDK. DS_JAVA_ADDITIONAL_ARGS is the extension slot in
# env.sh's DEFAULT_DS_JAVA_ARGS, so this survives both the image-baked and
# the chart-mounted env.sh; a runtime DS_JAVA_ADDITIONAL_ARGS override
# replaces this value -- include the flag there too.
ENV DS_JAVA_ADDITIONAL_ARGS=-XX:-UseBASE64Intrinsics

# The PingDS deployment uses PEM based certificates. This sets the location of the certs.
# This is set at docker *build* time. If you change this at runtime you must edit the config.ldif.
ENV PEM_KEYS_DIRECTORY "/var/run/secrets/keys/ds"
ENV PEM_TRUSTSTORE_DIRECTORY "/var/run/secrets/keys/truststore"

# Add the runtime scripts to be used if the deployer does not provide an implementation.
COPY --chown=forgerock:root runtime-scripts /opt/opendj/runtime-scripts
COPY --chown=forgerock:root *.sh /opt/opendj/

# Add custom schema files
RUN mkdir /opt/opendj/custom-schema
COPY --chown=forgerock:root config/schema/*.ldif /opt/opendj/custom-schema

# Add custom ldap configuration
COPY --chown=forgerock:root ldif-ext /opt/opendj/ldif-ext

# This is the basic PingDS setup from the PingDS repo. It does the bare bones
# setup - without any profiles. Profile setup will come later at runtime.
RUN ./ds-setup.sh && rm ./ds-setup.sh && rm -fr ldif-ext
