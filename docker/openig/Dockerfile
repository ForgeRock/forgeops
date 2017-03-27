#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
FROM tomcat:8.5-jre8

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
#ENV JAVA_OPTS -Dopenig.base=/root/openig
# Default home for OpenIG config. Override this to set a different location.
ENV OPENIG_BASE /var/openig
WORKDIR $CATALINA_HOME

# Let's remove some of the stuff we don't need.
RUN rm -fr webapps/*

# Note: By default Tomcat does NOT listen on 8443. You must add a custom server.xml file to change this.
EXPOSE 8080 8443

# Download your OpenIG war file to this directory.
ADD openig.war /tmp/openig.war

RUN unzip -q /tmp/openig.war -d /usr/local/tomcat/webapps/ROOT && rm -f /tmp/openig.war

# Example of adding config to the container to create an immutable image:
ADD sample-config/* /var/openig/config/