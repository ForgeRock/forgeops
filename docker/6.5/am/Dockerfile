FROM gcr.io/forgeops-public/am-base:6.5

# BEGIN tools for testing if the ds-idrepo is configured before AM starts.
# Installs ldap utils for querying the repo.
USER root

# Attempt debian installs first. Attempt alpine installs as fallback
RUN ( apt-get update && apt-get install -y ldap-utils && apt-get clean all ) || ( apk add openldap-clients )

USER forgerock

ENV CATALINA_OPTS "-XX:MaxRAMPercentage=75.0 -Dcom.iplanet.services.stats.state=off -Djavax.net.ssl.trustStore=/var/run/secrets/truststore/cacerts -Djavax.net.ssl.trustStorePassword=changeit -D"

COPY --chown=forgerock:root openam /home/forgerock/openam

# Note that the upstream AM image does not execute our custom script. We override here
ENTRYPOINT ["/home/forgerock/openam/boot.sh"]
