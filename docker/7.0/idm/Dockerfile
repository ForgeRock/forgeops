# Note: M5 integration with AM currently not working
FROM gcr.io/forgerock-io/idm:7.0.0-6a66039816ef4e4f4c7ebf1f6c64d23824672466

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
