FROM gcr.io/forgerock-io/openam:6.5.2

# BEGIN tools for testing if the ds-idrepo is configured before AM starts.
# Installs ldap utils for querying the repo.
USER root

# For debian
#RUN apt-get update && apt-get install ldap-utils
# Alpine:

RUN apk add openldap-clients

USER forgerock

# We now use path based routing - so AM must be deployed on /am
RUN mv /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/am


COPY --chown=forgerock:root openam /home/forgerock/openam

# Note that the upstream AM image does not execute our custom script. We override here
ENTRYPOINT ["/home/forgerock/openam/boot.sh"]
