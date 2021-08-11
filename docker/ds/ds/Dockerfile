# Multistage build of the DS image used by the ds-operator
# The operator runs setup at runtime, not docker build time. It is a
# fully "mutable", database like image - where all volatile data (including configuration and schema)
# is on a PVC. This behaves like a traditonal VM
FROM gcr.io/forgerock-io/ds/pit1:7.2.0-latest-postcommit

COPY --chown=forgerock:root default-scripts /opt/opendj/default-scripts
COPY --chown=forgerock:root ldif-ext /opt/opendj/ldif-ext

# This creates sample "prototype" backends for the CDK deployment. This is not required
# and is done to accelerate the cdk startup.
# When complete, a tar file is created with the prototype backends.
# If the user does not supply a setup script, this tar file will be unpacked to the data/ PVC
RUN default-scripts/setup && tar cvfz idrepo.tar.z config db changelogDb locks var

# Final stage - copies in the tar file from the first stage.
FROM gcr.io/forgerock-io/ds/pit1:7.2.0-latest-postcommit
WORKDIR /opt/opendj

COPY --from=0 --chown=forgerock:root /opt/opendj/idrepo.tar.z /opt/opendj/
COPY --chown=forgerock:root default-scripts /opt/opendj/default-scripts
COPY --chown=forgerock:root ldif-ext /opt/opendj/ldif-ext
COPY --chown=forgerock:root *.sh /opt/opendj/