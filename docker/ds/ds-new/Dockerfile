# Mutable DS image used by the ds-operator
#
# This image is designed to run setup at runtime, not docker build time. It is a
# fully "mutable", database like image - where all volatile data (including configuration and schema)
# is on a PVC. This behaves like a traditonal VM
FROM gcr.io/forgerock-io/ds-empty/pit1:7.3.0-latest-postcommit

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

# Add th default scripts to be used if the deployer does not provide an implementation.
# See default-scripts/setup
COPY --chown=forgerock:root default-scripts /opt/opendj/default-scripts
COPY --chown=forgerock:root ldif-ext /opt/opendj/ldif-ext
COPY --chown=forgerock:root *.sh /opt/opendj/

# This is the basic DS setup from the DS repo. It does the bare bones
# setup - without any profiles. Profile setup will come later at runtime.
RUN ./ds-setup.sh && rm ./ds-setup.sh && rm -fr ldif-ext