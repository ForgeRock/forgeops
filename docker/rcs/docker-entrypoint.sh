#!/bin/sh

CONNECTOR_SERVER_HOME="${CONNECTOR_SERVER_HOME:-/opt/openicf}"

TRUST_STORE="${CONNECTOR_SERVER_HOME}/security/truststore"
TRUSTED_CERTS_DIR="${CONNECTOR_SERVER_HOME}/trusted-cas"
if [ -d "$TRUSTED_CERTS_DIR" ]
then
  for certfile in "$TRUSTED_CERTS_DIR"/*
  do
    keytool -keystore "$TRUST_STORE" -storepass changeit -trustcacerts -import -file "$certfile" -alias "$(basename "$certfile")" -noprompt
  done
fi

# Build the JVM trust-store argument. Only override the JDK's default
# (cacerts) when a trust-store actually exists: in client mode the RCS dials
# publicly-CA-signed tenants (wss://.../openicf, https://.../access_token),
# and a trust-store holding only the deployer's rcs-certs PEMs would drop
# the public CAs and fail every handshake. When no certs were supplied the
# file doesn't exist at all, and pointing java at it fails TLS entirely.
TRUST_STORE_ARG=""
if [ -f "$TRUST_STORE" ]; then
  TRUST_STORE_ARG="-Djavax.net.ssl.trustStore=${TRUST_STORE}"
fi

JAVA_OPTS="${JAVA_OPTS:- -server -XX:MaxRAMPercentage=80 -XshowSettings:vm}"
MAIN_CLASS="org.forgerock.openicf.framework.server.Main"
CLASSPATH="$CONNECTOR_SERVER_HOME/lib/framework/*:$CONNECTOR_SERVER_HOME/lib/framework/"

OPENICF_OPTS="-Dconnectorserver.connectorServerName=$(hostname)"
if [ -n "$RCS_CLIENT_ID" ] && [ -n "$RCS_CLIENT_SECRET" ] ; then
  OPENICF_OPTS="$OPENICF_OPTS \
    -Dconnectorserver.clientId=${RCS_CLIENT_ID} \
    -Dconnectorserver.clientSecret=${RCS_CLIENT_SECRET}"
elif [ -n "$RCS_KEY_PASSWORD" ] ; then
  # The chart passes the shared password; the connector server wants the
  # key-hash form: base64(sha1(utf-16be(password))). The busybox toolchain
  # in the base image (iconv/sha1sum/xxd/base64) implements the chain the
  # chart README documents. RCS_KEY (the pre-computed hash) still wins when
  # set directly, for deployers managing the derivation themselves.
  RCS_KEY="$(echo -n "$RCS_KEY_PASSWORD" | iconv -t utf-16be | xxd -p | tr -d '\n' | xxd -r -p | sha1sum | cut -d' ' -f1 | xxd -r -p | base64 | tr -d '\n')"
  OPENICF_OPTS="$OPENICF_OPTS -Dconnectorserver.key=${RCS_KEY}"
elif [ -n "$RCS_KEY" ] ; then
  OPENICF_OPTS="$OPENICF_OPTS -Dconnectorserver.key=${RCS_KEY}"
else
  echo "ERROR!! Missing credentials. Must provide RCS_KEY or RCS_KEY_PASSWORD or RCS_CLIENT_SECRET and RCS_CLIENT_ID"
  exit 1
fi

echo "Starting RCS"

exec java ${JAVA_OPTS} ${OPENICF_OPTS} \
    ${TRUST_STORE_ARG} \
    -Djava.awt.headless=true \
    -classpath "${CLASSPATH}" \
    $MAIN_CLASS -service \
    -properties "$CONNECTOR_SERVER_HOME/conf/ConnectorServer.properties"
