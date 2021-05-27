FROM gcr.io/forgerock-io/ds/pit1:7.2.0-2021-6-5294c6b8a7f195ce7a5e71bc13f68781f0d973c7

# If you want to update any o/s software, or require root access, uncomment the lines below
# Ensure that the /opt/opendj is owned by forgeorock:root
# USER root
# RUN chown -R forgerock:root /opt/opendj
# USER forgerock
WORKDIR  /opt/opendj

COPY --chown=forgerock:root common  /opt/opendj/
COPY --chown=forgerock:root proxy  /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts

# To experiment with a modified entrypoint, uncomment:
# COPY --chown=forgerock:root scripts/docker-entrypoint.sh /opt/opendj

# This primes the idrepo datastore with the required base policy entries in ou=am-config
# This can be removed once AM can create these itself. See AME-19010
RUN chmod +w  template/setup-profiles/AM/config/6.5/base-entries.ldif && cat scripts/external-am-datastore.ldif >> template/setup-profiles/AM/config/6.5/base-entries.ldif

RUN bin/setup.sh && \
    bin/relax-security-settings.sh  && \
    rm bin/setup.sh bin/relax-security-settings.sh
