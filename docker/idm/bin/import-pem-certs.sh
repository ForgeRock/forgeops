#!/bin/sh
# The IDM PEM truststore import, shared by the Debian and Alpine image
# lines. The system CA bundle path differs per image line, and the chart
# always sets IDM_PEM_TRUSTSTORE explicitly per mode (see the
# truststore-init env in idm-deployment.yaml) — there is deliberately NO
# default in this script.
# This script copies the default cacerts to $TRUSTSTORE_PATH
# and imports all the certs contained in the $IDM_PEM_TRUSTSTORE if it exists

#
# Copyright 2019-2025 Ping Identity Corporation. All Rights Reserved
#
# This code is to be used exclusively in connection with Ping Identity
# Corporation software or services. Ping Identity Corporation only offers
# such software or services to legal entities who have entered into a
# binding license agreement with Ping Identity Corporation.
#

# POSIX sh with NO `set -o pipefail`: the merged tree runs under dash
# (/bin/sh) on the Debian images, and dash rejects pipefail outright
# ("Illegal option"). The one pipeline whose middle segment could fail
# (grep | wc) has its result range-checked; the keytool pipeline ends in
# || /bin/true, so pipefail adds nothing here.
set -e

IDM_DEFAULT_TRUSTSTORE=${IDM_DEFAULT_TRUSTSTORE:-$JAVA_HOME/lib/security/cacerts}
# NO default for IDM_PEM_TRUSTSTORE: the chart's truststore-init env always
# sets it explicitly per image line (Debian /usr/lib/ssl/cert.pem, Alpine
# /etc/ssl/certs/ca-certificates.crt). A fallback default would be wrong on
# one of the two lines by construction — and since Debian also ships the
# alpine path, a default would turn a misconfigured invocation (unset env)
# into a silent whole-system-CA import instead of the loud "Nothing was
# imported" diagnostic below.
# If a $IDM_PEM_TRUSTSTORE is provided, import it into the truststore. Otherwise, do nothing
if [ -f "$IDM_DEFAULT_TRUSTSTORE" ] && { [ -f "$IDM_PEM_TRUSTSTORE" ] || [ -f "$IDM_PEM_TRUSTSTORE_DS" ] || [ -f "$IDM_PEM_TRUSTSTORE_EXTRA" ] ; }; then
    TRUSTSTORE_PATH="${TRUSTSTORE_PATH:-/opt/openidm/idmtruststore}"
    TRUSTSTORE_PASSWORD="${TRUSTSTORE_PASSWORD:-changeit}"
    echo "Copying ${IDM_DEFAULT_TRUSTSTORE} to ${TRUSTSTORE_PATH}"
    cp ${IDM_DEFAULT_TRUSTSTORE} ${TRUSTSTORE_PATH}
    # Combine certs in a single file. Use a temp dir: the working directory
    # may not be writable when the init container runs as a non-owner uid
    # (the Debian image's CWD happened to be writable; an Alpine image's
    # /opt/openidm is owned by a different uid).
    WORKDIR_TMP=$(mktemp -d)
    cd "$WORKDIR_TMP"
    touch idm_combined_truststore
    [ -f "$IDM_PEM_TRUSTSTORE" ] && cat $IDM_PEM_TRUSTSTORE >> idm_combined_truststore
    [ -f "$IDM_PEM_TRUSTSTORE_DS" ] && cat $IDM_PEM_TRUSTSTORE_DS >> idm_combined_truststore
    [ -f "$IDM_PEM_TRUSTSTORE_EXTRA" ] && cat $IDM_PEM_TRUSTSTORE_EXTRA >> idm_combined_truststore
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
                    -storepass "${TRUSTSTORE_PASSWORD}" || /bin/true
    done
    echo "Import complete!"
    cd /
    rm -rf "$WORKDIR_TMP"
else
    echo "Nothing was imported to the truststore. Check ENVs IDM_DEFAULT_TRUSTSTORE and IDM_PEM_TRUSTSTORE"
    exit 1
fi
