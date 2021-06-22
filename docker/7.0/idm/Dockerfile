# Note: M5 integration with AM currently not working
FROM gcr.io/forgerock-io/idm/pit1:7.2.0-c60361f13a9c5a9d5043ae3479c4038f7e8f14ad

# Harden IDM by removing the Felix OSGI Console. Unless you are a ForgeRock developer, the
# console is rarely required. Your configuration should NOT include conf/felix.webconsole.json
RUN rm -f bundle/org.apache.felix.webconsole*.jar  && \
    rm -f bundle/openidm-felix-webconsole-*.jar

# Removes unwanted default config bundled out of the box.
RUN rm conf/felix.webconsole.json
RUN rm conf/selfservice.propertymap.json

# Remove this once https://bugster.forgerock.org/jira/browse/OPENIDM-16100 is integrated
# This sets the RAM based on cgroups to 65% of the container memory
ENV JAVA_OPTS -XX:MaxRAMPercentage=65 -XX:InitialRAMPercentage=65 -XX:MaxTenuringThreshold=1 -Djava.security.egd=file:/dev/urandom -XshowSettings:vm  -XX:+PrintFlagsFinal

COPY --chown=forgerock:root . /opt/openidm
