#
# Copyright (c) 2016-2018 ForgeRock AS.
FROM forgerock/downloader

ARG VERSION="6.5.0"

RUN download -v $VERSION openig

FROM tomcat:8.5-alpine



# Default home for OpenIG config. Override this to set a different location.
ENV OPENIG_BASE /var/openig
ENV FORGEROCK_HOME /opt/forgerock

# Delete the default webapps 
RUN rm -fr ${CATALINA_HOME}/webapps/*  && mkdir -p ${OPENIG_BASE}

COPY --from=0 /openig.war "$CATALINA_HOME"/webapps/ROOT.war

ENV CATALINA_OPTS -server -Xmx756m

# bind-tools for dig (dns diagnostics)
# iputils - ping command
# Note that we are adding the forgerock user to the root group - which is consistent with OpenShift.
# We make sure the tomcat directories can be written by the group.
# This is a work around for: https://github.com/docker-library/tomcat/issues/35
RUN apk add --no-cache su-exec unzip curl bash vim bind-tools iputils tini \
    && rm -fr "$CATALINA_HOME"/webapps/ROOT \
    && mkdir -p /opt/forgerock \
    && addgroup -g 11111 forgerock \
    && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G root forgerock \
    && chown -R forgerock:root "$CATALINA_HOME" "$FORGEROCK_HOME" \
    && chmod -R g+rwx "$CATALINA_HOME"


# Note: By default Tomcat does NOT listen on 8443. You must add a custom server.xml file to change this.
EXPOSE 8080

COPY server.xml "$CATALINA_HOME"/conf/server.xml

USER 11111

CMD ["/sbin/tini", "-v", "--", "catalina.sh", "run"]