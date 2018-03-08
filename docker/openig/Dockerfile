#
# Copyright (c) 2016-2017 ForgeRock AS.
FROM tomcat:8.5.28-jre8-alpine

ENV FORGEROCK_HOME /opt/forgerock

ENV CATALINA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap


# bind-tools for dig (dns diagnostics)
# iputils - ping command
# Note that we are adding the forgerock user to the root group - which is consistent with OpenShift.
# We make sure the tomcat directories can be written by the group.
# This is a work around for: https://github.com/docker-library/tomcat/issues/35
RUN apk add --no-cache su-exec unzip curl bash vim bind-tools iputils \
    && rm -fr "$CATALINA_HOME"/webapps/* \
    && mkdir -p /opt/forgerock \
    && addgroup -g 11111 forgerock \
    && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G root forgerock \
    && chown -R forgerock:root "$CATALINA_HOME" \
    && chown -R forgerock:root  "$FORGEROCK_HOME" \
    && chmod -R g+rwx "$CATALINA_HOME"


# Default home for OpenIG config. Override this to set a different location.
ENV OPENIG_BASE /var/openig

# Note: By default Tomcat does NOT listen on 8443. You must add a custom server.xml file to change this.
EXPOSE 8080

COPY server.xml "$CATALINA_HOME"/conf/server.xml

# Download your OpenIG war file to this directory.
COPY openig.war /tmp/openig.war

RUN unzip -q /tmp/openig.war -d /usr/local/tomcat/webapps/ROOT \
    && rm -f /tmp/openig.war \
    && mkdir /var/openig \
    && chown -R forgerock /usr/local/tomcat $OPENIG_BASE

# Example of adding config to the container to create an immutable image:
# COPY sample-config/* /var/openig/config/

USER 11111
