# Use publicly available am image for evaluation
FROM gcr.io/forgerock-io/openam:6.5.2

# Use a custom am-base image. See forgeops/docker/6.5/am-base/README
#FROM am-base:latest

# BEGIN tools for testing if the ds-idrepo is configured before AM starts.
# Installs ldap utils for querying the repo.
USER root

# Attempt debian installs first. Attempt alpine installs as fallback
RUN ( apt-get update && apt-get install -y ldap-utils && apt-get clean all ) || ( apk add openldap-clients )

USER forgerock

# We now use path based routing - so AM must be deployed on /am
RUN mv /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/am


ENV CATALINA_OPTS "-server -Xmx1g -Dcom.iplanet.services.stats.state=off -Djavax.net.ssl.trustStore=/var/run/secrets/truststore/cacerts -Djavax.net.ssl.trustStorePassword=changeit -D"

COPY --chown=forgerock:root openam /home/forgerock/openam

# Note that the upstream AM image does not execute our custom script. We override here
ENTRYPOINT ["/home/forgerock/openam/boot.sh"]
