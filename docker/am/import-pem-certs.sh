#!/usr/bin/env bash
# This script copies the default cacerts to $TRUSTSTORE_PATH 
# and imports all the certs contained in the $AM_PEM_TRUSTSTORE if it exists

#
# Copyright 2023 ForgeRock AS. All Rights Reserved
#

set -e 
set -o pipefail

AM_DEFAULT_TRUSTSTORE=${AM_DEFAULT_TRUSTSTORE:-$JAVA_HOME/lib/security/cacerts}
# If a $AM_PEM_TRUSTSTORE is provided, import it into the truststore. Otherwise, do nothing
if [ -f "$AM_DEFAULT_TRUSTSTORE" ] && ( [ -f "$AM_PEM_TRUSTSTORE" ] || [ -f "$AM_PEM_TRUSTSTORE_DS" ] ); then
    TRUSTSTORE_PATH="${TRUSTSTORE_PATH:-/home/forgerock/amtruststore}"
    TRUSTSTORE_PASSWORD="${TRUSTSTORE_PASSWORD:-changeit}"
    echo "Copying ${AM_DEFAULT_TRUSTSTORE} to ${TRUSTSTORE_PATH}"
    cp ${AM_DEFAULT_TRUSTSTORE} ${TRUSTSTORE_PATH}
    # Combine certs in a single file
    cat $AM_PEM_TRUSTSTORE $AM_PEM_TRUSTSTORE_DS > am_combined_truststore
    # Calculate the number of certs in the PEM file
    CERTS=$(grep 'END CERTIFICATE' am_combined_truststore| wc -l)
    echo "Found (${CERTS}) certificates in am_combined_truststore"
    echo "Importing (${CERTS}) certificates into ${TRUSTSTORE_PATH}"
    # For every cert in the PEM file, extract it and import into the JKS truststore
    for N in $(seq 0 $(($CERTS - 1))); do
        ALIAS="imported-certs-$N"
        cat am_combined_truststore |
            awk "n==$N { print }; /END CERTIFICATE/ { n++ }" |
            keytool -noprompt -importcert -trustcacerts -storetype JKS \
                    -alias "${ALIAS}" -keystore "${TRUSTSTORE_PATH}" \
                    -storepass "${TRUSTSTORE_PASSWORD}"
    done
    echo "Import complete!"
else
    echo "Nothing was imported to the truststore. Check ENVs AM_DEFAULT_TRUSTSTORE and AM_PEM_TRUSTSTORE"
    exit -1
fi
