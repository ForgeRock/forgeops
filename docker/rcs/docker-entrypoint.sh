#!/bin/bash

CONNECTOR_SERVER_HOME="${CONNECTOR_SERVER_HOME:-/opt/openicf}"

TRUST_STORE="${CONNECTOR_SERVER_HOME}/security/truststore"
TRUSTED_CERTS_DIR="${CONNECTOR_SERVER_HOME}/trusted-cas"
if [ -d $TRUSTED_CERTS_DIR ]
then
  ls ${TRUSTED_CERTS_DIR} | while read certfile
  do 
    keytool -keystore $TRUST_STORE -storepass changeit -trustcacerts -import -file $TRUSTED_CERTS_DIR/$certfile -alias $certfile -noprompt
  done
fi 

JAVA_OPTS="${JAVA_OPTS:- -server -XX:MaxRAMPercentage=80 -XshowSettings:vm}"
MAIN_CLASS="org.forgerock.openicf.framework.server.Main"
CLASSPATH="$CONNECTOR_SERVER_HOME/lib/framework/*:$CONNECTOR_SERVER_HOME/lib/framework/"

OPENICF_OPTS="\
    -Dconnectorserver.connectorServerName=`hostname` \
    -Dconnectorserver.clientId=${RCS_CLIENT_ID} \
    -Dconnectorserver.clientSecret=${RCS_CLIENT_SECRET}"

echo "Starting RCS"

exec java ${JAVA_OPTS} ${OPENICF_OPTS} \
    -Djavax.net.ssl.trustStore=${TRUST_STORE} \
    -Djava.awt.headless=true \
    -classpath "${CLASSPATH}" \
    $MAIN_CLASS -service \
    -properties "$CONNECTOR_SERVER_HOME/conf/ConnectorServer.properties"
