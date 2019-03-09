FROM forgerock-docker-public.bintray.io/forgerock/openidm:7.0.0

# Removes any existing conf files that might conflict with our config. This includes the embedded ds repo.
RUN rm -fr /opt/openidm/conf 
COPY --chown=forgerock:root . /opt/openidm
