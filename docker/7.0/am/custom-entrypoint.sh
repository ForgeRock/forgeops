#!/usr/bin/env bash
# This script copies the default cacerts to $TRUSTSTORE_PATH 
# and imports all the certs contained in the $AM_PEM_TRUSTSTORE if it exists

#
# Copyright 2019-2021 ForgeRock AS. All Rights Reserved
#

set -e 
set -o pipefail

# AM_PEM_TRUSTSTORE="${AM_PEM_TRUSTSTORE:-/var/run/secrets/truststore/cacerts}"

AM_DEFAULT_TRUSTSTORE=${AM_DEFAULT_TRUSTSTORE:-$JAVA_HOME/lib/security/cacerts}
# If a $AM_PEM_TRUSTSTORE is provided, import it into the truststore. Otherwise, do nothing
if [ -f "$AM_DEFAULT_TRUSTSTORE" ] && [ -f "$AM_PEM_TRUSTSTORE" ]; then
    TRUSTSTORE_PATH="${TRUSTSTORE_PATH:-/home/forgerock/amtruststore}"
    TRUSTSTORE_PASSWORD="${TRUSTSTORE_PASSWORD:-changeit}"
    echo "Copying ${AM_DEFAULT_TRUSTSTORE} to ${TRUSTSTORE_PATH}"
    cp ${AM_DEFAULT_TRUSTSTORE} ${TRUSTSTORE_PATH}
    # Calculate the number of certs in the PEM file
    CERTS=$(grep 'END CERTIFICATE' $AM_PEM_TRUSTSTORE| wc -l)
    echo "Found (${CERTS}) certificates in $AM_PEM_TRUSTSTORE"
    echo "Importing (${CERTS}) certificates into ${TRUSTSTORE_PATH}"
    # For every cert in the PEM file, extract it and import into the JKS truststore
    for N in $(seq 0 $(($CERTS - 1))); do
        ALIAS="${AM_PEM_TRUSTSTORE%.*}-$N"
        cat $AM_PEM_TRUSTSTORE |
            awk "n==$N { print }; /END CERTIFICATE/ { n++ }" |
            keytool -noprompt -import -trustcacerts -storetype PKCS12 \
                    -alias "${ALIAS}" -keystore "${TRUSTSTORE_PATH}" \
                    -storepass "${TRUSTSTORE_PASSWORD}"
    done
    echo "Import complete!"
fi
# If $TRUSTORE_PATH AND $TRUSTSTORE_PASS are set, update $CATALINA_OPTS
if [ ! -z "$TRUSTSTORE_PATH" ] && [ ! -z "$TRUSTSTORE_PATH" ]; then
    export CATALINA_OPTS="$CATALINA_OPTS -Djavax.net.ssl.trustStore=$TRUSTSTORE_PATH \
                                         -Djavax.net.ssl.trustStorePassword=$TRUSTSTORE_PASSWORD \
                                         -Djavax.net.ssl.trustStoreType=jks" 
fi
exec /home/forgerock/docker-entrypoint.sh
