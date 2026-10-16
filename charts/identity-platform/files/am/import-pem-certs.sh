#!/bin/sh
# The AM PEM truststore import, shared by the Debian and Alpine image lines.
# This script copies the default cacerts to $TRUSTSTORE_PATH
# and imports all the certs contained in the $AM_PEM_TRUSTSTORE if it exists

#
# Copyright 2023-2025 Ping Identity Corporation. All Rights Reserved
#
# This code is to be used exclusively in connection with Ping Identity
# Corporation software or services. Ping Identity Corporation only offers
# such software or services to legal entities who have entered into a
# binding license agreement with Ping Identity Corporation.
#

# POSIX sh with NO `set -o pipefail`: the merged tree runs under dash
# (/bin/sh) on the Debian images, and dash rejects pipefail outright
# ("Illegal option"). The keytool pipeline ends in || /bin/true, so
# pipefail adds nothing here.
set -e

AM_DEFAULT_TRUSTSTORE=${AM_DEFAULT_TRUSTSTORE:-$JAVA_HOME/lib/security/cacerts}
# If a $AM_PEM_TRUSTSTORE is provided, import it into the truststore. Otherwise, do nothing
if [ -f "$AM_DEFAULT_TRUSTSTORE" ] && { [ -f "$AM_PEM_TRUSTSTORE" ] || [ -f "$AM_PEM_TRUSTSTORE_DS" ] || [ -f "$AM_PEM_TRUSTSTORE_EXTRA" ] ; }; then
    # The alpine pingbase images bake FORGEROCK_HOME=/home/ping; the Debian
    # images set nothing -> /home/forgerock. The chart sets TRUSTSTORE_PATH
    # explicitly for the truststore-init container, so this default is a
    # fallback only.
    TRUSTSTORE_PATH="${TRUSTSTORE_PATH:-${FORGEROCK_HOME:-/home/forgerock}/amtruststore}"
    TRUSTSTORE_PASSWORD="${TRUSTSTORE_PASSWORD:-changeit}"
    echo "Copying ${AM_DEFAULT_TRUSTSTORE} to ${TRUSTSTORE_PATH}"
    cp ${AM_DEFAULT_TRUSTSTORE} ${TRUSTSTORE_PATH}
    # Combine certs in a single file. Use a temp dir: the working directory
    # may not be writable when the init container runs as a non-owner uid
    # (measured: the alpine pingam image's WORKDIR /usr/local/tomcat is
    # owned by 11111, so the forgeops-mode uid 9031 cannot touch files
    # there — the same hazard the IDM twin documents).
    WORKDIR_TMP=$(mktemp -d)
    # Unconditional cleanup: under set -e a mid-import failure (keytool,
    # malformed PEM) must not strand the temp dir.
    trap 'cd /; rm -rf "$WORKDIR_TMP"' EXIT
    cd "$WORKDIR_TMP"
    touch am_combined_truststore
    [ -f "$AM_PEM_TRUSTSTORE" ] && cat $AM_PEM_TRUSTSTORE >> am_combined_truststore
    [ -f "$AM_PEM_TRUSTSTORE_DS" ] && cat $AM_PEM_TRUSTSTORE_DS >> am_combined_truststore
    [ -f "$AM_PEM_TRUSTSTORE_EXTRA" ] && cat $AM_PEM_TRUSTSTORE_EXTRA >> am_combined_truststore
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
                    -storepass "${TRUSTSTORE_PASSWORD}" || /bin/true
    done
    echo "Import complete!"
else
    echo "Nothing was imported to the truststore. Check ENVs AM_DEFAULT_TRUSTSTORE and AM_PEM_TRUSTSTORE"
    exit 1
fi
