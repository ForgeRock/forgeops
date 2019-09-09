# Note: M5 integration with AM currently not working
FROM gcr.io/forgerock-io/idm/pit1:7.0.0-1a6433121f6f6c23f0034dc772192d9a3a92b7a1

# Harden IDM by removing the Felix OSGI Console. Unless you are a ForgeRock developer, the
# console is rarely required. Your configuration should NOT include conf/felix.webconsole.json
RUN rm bundle/org.apache.felix.webconsole*.jar  && \
    rm bundle/openidm-felix-webconsole-*.jar

# Removes any existing conf files that might conflict with our config. This includes the embedded ds repo.
RUN rm -fr /opt/openidm/conf
COPY --chown=forgerock:root . /opt/openidm
