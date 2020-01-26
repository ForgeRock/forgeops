# Note: M5 integration with AM currently not working
FROM gcr.io/forgerock-io/idm:7.0.0-0c74571640c73a272e1c1d7fea27ae916de017d9

# Harden IDM by removing the Felix OSGI Console. Unless you are a ForgeRock developer, the
# console is rarely required. Your configuration should NOT include conf/felix.webconsole.json
RUN rm bundle/org.apache.felix.webconsole*.jar  && \
    rm bundle/openidm-felix-webconsole-*.jar

# Removes any existing conf files that might conflict with our config. This includes the embedded ds repo.
RUN rm -fr /opt/openidm/conf
ENV JAVA_OPTS "-server -XX:MaxRAMPercentage=75"
COPY --chown=forgerock:root . /opt/openidm
# Workaround for Kaniko issue
USER root
RUN chown -R forgerock:root /opt/openidm
USER forgerock