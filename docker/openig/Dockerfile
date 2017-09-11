#
# Copyright (c) 2016-2017 ForgeRock AS.
FROM forgerock/tomcat:5.5.0

# Default home for OpenIG config. Override this to set a different location.
ENV OPENIG_BASE /var/openig

# Note: By default Tomcat does NOT listen on 8443. You must add a custom server.xml file to change this.
EXPOSE 8080

# Download your OpenIG war file to this directory.
ADD openig.war /tmp/openig.war

RUN unzip -q /tmp/openig.war -d /usr/local/tomcat/webapps/ROOT \
    && rm -f /tmp/openig.war \
    && chown -R forgerock /usr/local/tomcat

# Example of adding config to the container to create an immutable image:
# ADD sample-config/* /var/openig/config/

USER forgerock
