#!/usr/bin/env bash
# This script copies the default cacerts to $TRUSTSTORE_PATH 
# and imports all the certs contained in the $SOURCE_PEM_FILE if it exists

#
# Copyright 2019-2021 ForgeRock AS. All Rights Reserved
#

set -e 
set -o pipefail

# SOURCE_PEM_FILE="${SOURCE_PEM_FILE:-/var/run/secrets/truststore/cacerts}"
export TRUSTSTORE_PATH="${TRUSTSTORE_PATH:-/home/forgerock/amtruststore}"
export TRUSTSTORE_PASSWORD="${TRUSTSTORE_PASSWORD:-changeit}"

SOURCE_TRUSTSTORE=${JAVA_HOME}/lib/security/cacerts


if [ ! -f "$SOURCE_TRUSTSTORE" ]; then
    echo "$SOURCE_TRUSTSTORE is not a valid file or does not exist."
    echo "check the value of \$SOURCE_TRUSTSTORE and restart the pod"
    exit 1
fi

echo "Copying ${SOURCE_TRUSTSTORE} to ${TRUSTSTORE_PATH}"
cp ${SOURCE_TRUSTSTORE} ${TRUSTSTORE_PATH}

# If a $SOURCE_PEM_FILE is provice, import it into the truststore. Otherwise, use the trustore as-is
echo "Attempting to import PEM File into truststore"
if [ ! -f "$SOURCE_PEM_FILE" ]; then
    echo "$SOURCE_PEM_FILE is not a valid file or does not exist."
    echo "Will use ${TRUSTSTORE_PATH} as-is. No import will be done"
else
    echo "Found: ${SOURCE_PEM_FILE}"
    # Calculate the number of certs in the PEM file
    CERTS=$(grep 'END CERTIFICATE' $SOURCE_PEM_FILE| wc -l)
    echo "Found (${CERTS}) certificates in the provided PEM file."
    echo "Will import certs into truststore: ${TRUSTSTORE_PATH}"
    # For every cert in the PEM file, extract it and import into the JKS truststore
    for N in $(seq 0 $(($CERTS - 1))); do
    ALIAS="${SOURCE_PEM_FILE%.*}-$N"
    cat $SOURCE_PEM_FILE |
        awk "n==$N { print }; /END CERTIFICATE/ { n++ }" |
        keytool -noprompt -import -trustcacerts -storetype PKCS12 \
                -alias "${ALIAS}" -keystore "${TRUSTSTORE_PATH}" \
                -storepass "${TRUSTSTORE_PASSWORD}"
    done
    echo "Import complete!"    
fi

export CATALINA_OPTS="$CATALINA_OPTS -Djavax.net.ssl.trustStore=$TRUSTSTORE_PATH \
                                     -Djavax.net.ssl.trustStorePassword=$TRUSTSTORE_PASSWORD \
                                     -Djavax.net.ssl.trustStoreType=jks" 

exec /home/forgerock/docker-entrypoint.sh
