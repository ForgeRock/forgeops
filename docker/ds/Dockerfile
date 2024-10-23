ARG REPO=gcr.io/forgerock-io/ds-empty/pit1
ARG TAG=8.0.0-latest-postcommit

FROM ${REPO}:${TAG}

# FOR DEBUG. Remove for production deployment
USER root
RUN apt-get update && apt-get install -y --no-install-recommends vim ncat dnsutils 
USER forgerock

# The PVC mount point where all writeable data is stored.
ENV DS_DATA_DIR /opt/opendj/data

# The ds deployment uses PEM based certificates. This sets the location of the certs.
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

# This is the basic DS setup from the DS repo. It does the bare bones
# setup - without any profiles. Profile setup will come later at runtime.
RUN ./ds-setup.sh && rm ./ds-setup.sh && rm -fr ldif-ext
