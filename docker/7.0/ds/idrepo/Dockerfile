FROM gcr.io/forgerock-io/ds/pit1:7.2.0-209b0e68d24e84b07edc7f567a732fb0ca9f7f55

# If you want to update any o/s software, or require root access, uncomment the lines below
# Ensure that the /opt/opendj is owned by forgeorock:root
# USER root
# RUN chown -R forgerock:root /opt/opendj
# USER forgerock
WORKDIR  /opt/opendj

COPY --chown=forgerock:root common  /opt/opendj/
COPY --chown=forgerock:root idrepo  /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts

# Ldif for the alpha/bravo realm config
COPY --chown=forgerock:root idrepo/*.ldif  /var/tmp/

# This primes the idrepo datastore with the required base policy entries in ou=am-config
# AM does not yet dynamically create the realm policy entries when it attaches to a new dynamic config
# store - as is the case with File Based Config.
# This procedure concatenates the profiles for the base config store, the base external datastore and
# The alpha/bravo realms.
# This work was previously performed at runtime by the ldif loader. This moves it to a docker build time
# activity. The profiles will create the prototype configs which are used to prime the PVC.
#
# This can be removed once AM can create these itself. See https://bugster.forgerock.org/jira/browse/AME-19010
RUN chmod +w  template/setup-profiles/AM/config/6.5/base-entries.ldif \
        && cat scripts/external-am-datastore.ldif >> template/setup-profiles/AM/config/6.5/base-entries.ldif \
        && cat /var/tmp/alpha_bravo.ldif >> template/setup-profiles/AM/config/6.5/base-entries.ldif \
        && chmod +w template/setup-profiles/AM/identity-store/7.0/base-entries.ldif \
        && cat /var/tmp/orgs.ldif >> template/setup-profiles/AM/identity-store/7.0/base-entries.ldif \
        && rm /var/tmp/*ldif

RUN bin/setup.sh && \
    bin/relax-security-settings.sh  && \
    rm bin/setup.sh bin/relax-security-settings.sh
