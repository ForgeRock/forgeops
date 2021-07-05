FROM gcr.io/forgerock-io/ds/pit1:7.2.0-38210fbc4c591185ee01cb1e18c4d2ccb12b51ee

# If you want to update any o/s software, or require root access, uncomment the lines below
# Ensure that the /opt/opendj is owned by forgeorock:root
# USER root
# RUN chown -R forgerock:root /opt/opendj
# USER forgerock
WORKDIR  /opt/opendj

COPY --chown=forgerock:root common  /opt/opendj/
COPY --chown=forgerock:root proxy  /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts

# This primes the idrepo datastore with the required base policy entries in ou=am-config
# This can be removed once AM can create these itself. See AME-19010
RUN chmod +w  template/setup-profiles/AM/config/6.5/base-entries.ldif && cat scripts/external-am-datastore.ldif >> template/setup-profiles/AM/config/6.5/base-entries.ldif

RUN bin/setup.sh && \
    bin/relax-security-settings.sh  && \
    rm bin/setup.sh bin/relax-security-settings.sh
