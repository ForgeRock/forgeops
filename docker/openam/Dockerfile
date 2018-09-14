# AM Dockerfile
#
# Copyright (c) 2016-2018 ForgeRock AS.
#
FROM forgerock/downloader 

ARG VERSION="6.5.0-M4"
RUN download -v $VERSION openam 
RUN mkdir -p /var/tmp/openam && unzip -q /openam.war -d /var/tmp/openam

FROM tomcat:8.5-alpine

RUN rm -fr "$CATALINA_HOME"/webapps/*

COPY --from=0 /var/tmp/openam "$CATALINA_HOME"/webapps/openam

#ENV CATALINA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap
# Option for setting the AM home directory:
#    -Dcom.sun.identity.configuration.directory=/home/forgerock/openam
# Options for using cgroups for memory size:
#   -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap
# Option for sending debug output to stderr
#-Dcom.sun.identity.util.debug.provider=com.sun.identity.shared.debug.impl.StdOutDebugProvider -Dcom.sun.identity.shared.debug.file.format="%PREFIX% %MSG%\n%STACKTRACE%"
# -Duser.home=/home/forgerock
# See also https://forum.forgerock.com/topic/openamcfg-location/


# This option:
#  -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true \
# is disabled to avoid http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-0450 
# This may impact amster imports for some configurations (SAML entities)
# If you need to renable this for amster, it should be disabled after the import is complete

ENV CATALINA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dcom.sun.identity.util.debug.provider=com.sun.identity.shared.debug.impl.StdOutDebugProvider \
  -Dcom.sun.identity.shared.debug.file.format=\"%PREFIX% %MSG%\\n%STACKTRACE%\"

#  -Dcom.iplanet.services.debug.level=error

ENV FORGEROCK_HOME /home/forgerock
ENV OPENAM_HOME /home/forgerock/openam

# Note that we are adding the forgerock user to the root group - which is consistent with OpenShift.
# This is a work around for: https://github.com/docker-library/tomcat/issues/35
RUN apk add --no-cache su-exec unzip curl bash tini \
  && addgroup -g 11111 forgerock \
  && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D forgerock -G root \
  && mkdir -p "$OPENAM_HOME" \
  && mkdir -p "$FORGEROCK_HOME"/.openamcfg \
  && echo "$OPENAM_HOME" >  "$FORGEROCK_HOME"/.openamcfg/AMConfig_usr_local_tomcat_webapps_openam_  \
  && chown -R forgerock:root "$CATALINA_HOME" \
  && chown -R forgerock:root  "$FORGEROCK_HOME" \
  && chmod -R g+rwx "$CATALINA_HOME"


# The userid must be numeric.
USER 11111

# If you want to create an image that is ready to be bootstrapped to a
# configuration store, you can add a custom boot.json file.
# This can also be added at runtime by a ConfigMap or an init container.
#COPY boot.json /root/openam

# Generate a default keystore for SSL - only needed if you want SSL inside the cluster.
# You can mount your own keystore on the ssl/ directory to override this.
# Because of the complexity of configuring ssl, we recommend using something like istio to provide
# SSL within the cluster.
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
COPY server.xml "$CATALINA_HOME"/conf/server.xml

# For debugging AM in a container, uncomment this.
# Use something like  kubectl port-forward POD 5005:5005
# ENV CATALINA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005"

# Settings for Tomcat cache.
COPY context.xml "$CATALINA_HOME"/conf/context.xml

# Path to optional script to customize the AM web app. Use this script hook to copy in images, web.xml, etc.
ENV CUSTOMIZE_AM /home/forgerock/customize-am.sh


COPY *.sh $FORGEROCK_HOME/

ENTRYPOINT ["/home/forgerock/docker-entrypoint.sh"]

CMD ["run"]