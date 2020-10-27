#!/bin/bash

set -eox pipefail

chgPass () {
    local HOST=$1
    local ADMIN_PASS=$2
    local USER_DN=$3
    local USER_UID=$4
    local USER_PASS=$5
    local FULL_USER_DN="${USER_UID},${USER_DN}"
    echo "Checking ${HOST} for ${USER_UID},${USER_DN}"
    CXN="-h ${HOST} -p 1389 -w ${ADMIN_PASS}"
    ldapsearch ${CXN} -D "uid=admin" -b ${USER_DN} "${USER_UID}"  > /dev/null
    SEARCH_RESPONSE=$?
    case "${SEARCH_RESPONSE}" in
        "0")
            echo "Changing password of ${FULL_USER_DN}"
            ldappasswordmodify ${CXN} -D "uid=admin" -a "dn:${FULL_USER_DN}" -n "${USER_PASS}"
        ;;
        "32")
            echo "${FULL_USER_DN} not found, skipping..."
        ;;
        *)
            echo "ERROR: Error when searching for user, response $SEARCH_RESPONSE"
            exit 1
        ;;
    esac
}

ADMIN_PASS=$(cat /var/run/secrets/opendj-passwords/dirmanager.pw)

chgPass ds-idrepo-0.ds-idrepo ${ADMIN_PASS} ou=admins,ou=famrecords,ou=openam-session,ou=tokens "uid=openam_cts" ${AM_STORES_CTS_PASSWORD}
chgPass ds-idrepo-0.ds-idrepo ${ADMIN_PASS} ou=admins,ou=identities "uid=am-identity-bind-account" ${AM_STORES_USER_PASSWORD}
chgPass ds-idrepo-0.ds-idrepo ${ADMIN_PASS} ou=admins,ou=am-config "uid=am-config" ${AM_STORES_APPLICATION_PASSWORD}

chgPass ds-cts-0.ds-cts ${ADMIN_PASS} ou=admins,ou=famrecords,ou=openam-session,ou=tokens "uid=openam_cts" ${AM_STORES_CTS_PASSWORD}
# These are not required as the CTS is only used for tokens. Uncomment these if you ever wish to use the CTS store
# for user or config entries
#chgPass ds-cts-0.ds-cts ${ADMIN_PASS} ou=admins,ou=identities "uid=am-identity-bind-account" ${{AM_STORES_USER_PASSWORD}
#chgPass ds-cts-0.ds-cts ${ADMIN_PASS} ou=admins,ou=am-config "uid=am-config" ${AM_STORES_APPLICATION_PASSWORD}

echo "Password script finished"

echo "done"
