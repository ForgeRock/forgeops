# AM Dockerfile
#
# Copyright (c) 2016-2017 ForgeRock AS.
#
FROM tomcat:8.5.21-jre8-alpine


#ENV CATALINA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap
# Option for setting the AM home directory:
#    -Dcom.sun.identity.configuration.directory=/home/forgerock/openam
# Options for using cgroups for memory size:
#   -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap
# Option for sending debug output to stderr
#-Dcom.sun.identity.util.debug.provider=com.sun.identity.shared.debug.impl.StdOutDebugProvider -Dcom.sun.identity.shared.debug.file.format="%PREFIX% %MSG%\n%STACKTRACE%"

ENV CATALINA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true \
  -Dcom.sun.identity.util.debug.provider=com.sun.identity.shared.debug.impl.StdOutDebugProvider \
  -Dcom.sun.identity.shared.debug.file.format=\"%PREFIX% %MSG%\\n%STACKTRACE%\"

#  -Dcom.iplanet.services.debug.level=error

ENV FORGEROCK_HOME /home/forgerock
ENV OPENAM_HOME /home/forgerock/openam


ADD openam.war  /tmp/openam.war

# openldap-clients is needed to test for the configuration store.
RUN apk add --no-cache su-exec unzip curl bash openldap-clients \
  && rm -fr /usr/local/tomcat/webapps/* \
  && unzip -q /tmp/openam.war -d  "$CATALINA_HOME"/webapps/openam \
  && rm /tmp/openam.war \
  && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D forgerock \
  && mkdir -p $"OPENAM_HOME" \
  && mkdir -p "$FORGEROCK_HOME"/.openamcfg \
  && echo "$OPENAM_HOME" >  "$FORGEROCK_HOME"/.openamcfg/AMConfig_usr_local_tomcat_webapps_openam_  \
  && chown -R forgerock "$CATALINA_HOME" \
  && chown -R forgerock  "$FORGEROCK_HOME"


USER forgerock

# If you want to create an image that is ready to be bootstrapped to a
# configuration store, you can add a custom boot.json file.
# This can also be added at runtime by a ConfigMap.
#ADD boot.json /root/openam

# Generate a default keystore for SSL - only needed if you want SSL inside the cluster.
# You can mount your own keystore on the ssl/ directory to override this.
# Because of the complexity of configuring ssl, we should look at using istio.io to handle intercomponent ssl
#RUN mkdir -p /usr/local/tomcat/ssl && \
#   keytool -genkey -noprompt \
#     -keyalg RSA \
#     -alias tomcat \
#     -dname "CN=forgerock.com, OU=ID, O=FORGEROCK, L=Calgary, S=AB, C=CA" \
#     -keystore /usr/local/tomcat/ssl/keystore \
#     -storepass password \
#     -keypass password

# Custom server.xml: use this if AM is behind SSL termination.
# See the server.xml file for details.
ADD server.xml "$CATALINA_HOME"/conf/server.xml

# For debugging AM in a container, uncomment this.
# Use something like  kubectl port-forward POD 5005:5005
# ENV CATALINA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005"

# Settings for Tomcat cache.
ADD context.xml "$CATALINA_HOME"/conf/context.xml

# Path to optional script to customize the AM web app. Use this script hook to copy in images, web.xml, etc.
ENV CUSTOMIZE_AM /home/forgerock/customize-am.sh


ADD *.sh $FORGEROCK_HOME/

ENTRYPOINT ["/home/forgerock/docker-entrypoint.sh"]

CMD ["run"]