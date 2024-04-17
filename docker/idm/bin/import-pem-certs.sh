#!/usr/bin/env bash
# This script copies the default cacerts to $TRUSTSTORE_PATH 
# and imports all the certs contained in the $IDM_PEM_TRUSTSTORE if it exists

#
# Copyright 2019-2024 Ping Identity Corporation. All Rights Reserved
# 
# This code is to be used exclusively in connection with Ping Identity 
# Corporation software or services. Ping Identity Corporation only offers
# such software or services to legal entities who have entered into a 
# binding license agreement with Ping Identity Corporation.
#

set -e 
set -o pipefail

IDM_DEFAULT_TRUSTSTORE=${IDM_DEFAULT_TRUSTSTORE:-$JAVA_HOME/lib/security/cacerts}
# If a $IDM_PEM_TRUSTSTORE is provided, import it into the truststore. Otherwise, do nothing
if [ -f "$IDM_DEFAULT_TRUSTSTORE" ] && ( [ -f "$IDM_PEM_TRUSTSTORE" ] || [ -f "$IDM_PEM_TRUSTSTORE_DS" ] ); then
    TRUSTSTORE_PATH="${TRUSTSTORE_PATH:-/opt/openidm/idmtruststore}"
    TRUSTSTORE_PASSWORD="${TRUSTSTORE_PASSWORD:-changeit}"
    echo "Copying ${IDM_DEFAULT_TRUSTSTORE} to ${TRUSTSTORE_PATH}"
    cp ${IDM_DEFAULT_TRUSTSTORE} ${TRUSTSTORE_PATH}
    # Combine certs in a single file
    cat $IDM_PEM_TRUSTSTORE $IDM_PEM_TRUSTSTORE_DS > idm_combined_truststore
    # Calculate the number of certs in the PEM file
    CERTS=$(grep 'END CERTIFICATE' idm_combined_truststore| wc -l)
    echo "Found (${CERTS}) certificates in idm_combined_truststore"
    echo "Importing (${CERTS}) certificates into ${TRUSTSTORE_PATH}"
    # For every cert in the PEM file, extract it and import into the JKS truststore
    for N in $(seq 0 $(($CERTS - 1))); do
        ALIAS="imported-certs-$N"
        cat idm_combined_truststore |
            awk "n==$N { print }; /END CERTIFICATE/ { n++ }" |
            keytool -noprompt -importcert -trustcacerts -storetype JKS \
                    -alias "${ALIAS}" -keystore "${TRUSTSTORE_PATH}" \
                    -storepass "${TRUSTSTORE_PASSWORD}"
    done
    echo "Import complete!"
else
    echo "Nothing was imported to the truststore. Check ENVs IDM_DEFAULT_TRUSTSTORE and IDM_PEM_TRUSTSTORE"
    exit -1
fi