# Note: M5 integration with AM currently not working
FROM gcr.io/forgerock-io/idm/pit1:7.0.0-latest-postcommit

# Removes any existing conf files that might conflict with our config. This includes the embedded ds repo.
RUN rm -fr /opt/openidm/conf
COPY --chown=forgerock:root . /opt/openidm
