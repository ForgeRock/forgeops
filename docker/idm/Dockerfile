# Note: M5 integration with AM currently not working
FROM gcr.io/forgerock-io/idm/pit1:7.0.0-626afa9bd66fe2e220ecb85eb383e0c484bdcba0

# Harden IDM by removing the Felix OSGI Console. Unless you are a ForgeRock developer, the
# console is rarely required. Your configuration should NOT include conf/felix.webconsole.json
RUN rm bundle/org.apache.felix.webconsole*.jar  && \
    rm bundle/openidm-felix-webconsole-*.jar

# Removes any existing conf files that might conflict with our config. This includes the embedded ds repo.
RUN rm -fr /opt/openidm/conf
COPY --chown=forgerock:root . /opt/openidm
