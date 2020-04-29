# Note: M5 integration with AM currently not working
FROM gcr.io/forgerock-io/idm:7.0.0-53f17918c8a459d49f3126d1ee625b6ef382d0cb

# Harden IDM by removing the Felix OSGI Console. Unless you are a ForgeRock developer, the
# console is rarely required. Your configuration should NOT include conf/felix.webconsole.json
RUN rm bundle/org.apache.felix.webconsole*.jar  && \
    rm bundle/openidm-felix-webconsole-*.jar

# Removes any existing conf files that might conflict with our config. This includes the embedded ds repo.
RUN rm -fr /opt/openidm/conf
ENV JAVA_OPTS "-server -XX:MaxRAMPercentage=75"
COPY --chown=forgerock:root . /opt/openidm
