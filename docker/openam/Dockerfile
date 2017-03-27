# OpenAM Dockerfile
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

FROM tomcat:8.5-jre8

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
WORKDIR $CATALINA_HOME

# Note: By default, Tomcat does NOT listen on 8443. You must add a custom server.xml file to change this.
EXPOSE 8080 8443

ENV OPENAM_VERSION=14.0.0-SNAPSHOT

ADD openam.war  /tmp/openam.war

RUN rm -fr /usr/local/tomcat/webapps/* \
  && unzip -q /tmp/openam.war -d /usr/local/tomcat/webapps/openam \
  && rm /tmp/openam.war

# Premake the path and configuration directory.
RUN mkdir -p /root/openam/openam && mkdir -p /root/.openamcfg \
  && echo "/root/openam" > /root/.openamcfg/AMConfig_usr_local_tomcat_webapps_openam_

# If you want to create an image that is ready to be bootstrapped to a
# configuration store, you can add a custom boot.json file.
# This can also be added at runtime by a ConfigMap.
#ADD boot.json /root/openam

# Generate a default keystore for SSL - only needed if you want SSL inside the cluster
# You can mount your own keystore on the ssl/ directory to override this.
#RUN mkdir -p /usr/local/tomcat/ssl && \
#   keytool -genkey -noprompt \
#     -keyalg RSA \
#     -alias tomcat \
#     -dname "CN=forgerock.com, OU=ID, O=FORGEROCK, L=Calgary, S=AB, C=CA" \
#     -keystore /usr/local/tomcat/ssl/keystore \
#     -storepass password \
#     -keypass password

# Custom server.xml: use this if OpenAM is behind SSL termination.
# See the server.xml file for details.
ADD server.xml /usr/local/tomcat/conf/server.xml

# For debugging OpenAM in a container, uncomment this.
# Use something like  kubectl port-forward POD 5005:5005
# ENV CATALINA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005"

# Settings for Tomcat cache.
ADD context.xml /usr/local/tomcat/conf/context.xml
