#!/bin/bash

PS4='+ $(date "+%H:%M:%S")\011 '
set -eo pipefail

chgPass () {
    local HOST=$1
    local ADMIN_PASS=$2
    local USER_DN=$3
    local USER_UID=$4
    local USER_PASS=$5
    local FULL_USER_DN="${USER_UID},${USER_DN}"
    echo "Checking ${HOST} for ${USER_UID},${USER_DN}"
    CXN="-h ${HOST} -p 1636 --useSsl --trustAll"
    ldapsearch ${CXN} -D "uid=admin" -w "${ADMIN_PASS}" -b ${USER_DN} "${USER_UID}"  > /dev/null
    SEARCH_RESPONSE=$?
    echo ""
    echo "- Changing password of ${FULL_USER_DN}"
    case "${SEARCH_RESPONSE}" in
        "0")
            echo "ldapmodify ${CXN} -D \"uid=admin\" -w **** -a \"dn:${FULL_USER_DN}\" "
            ldapmodify ${CXN} -D "uid=admin" -w "${ADMIN_PASS}" <<EOM
dn: $FULL_USER_DN
changetype: modify
replace: userPassword
$USER_PASS
EOM
        ;;
        "32")
            echo "ERROR: ${FULL_USER_DN} not found, skipping..."
            exit 1
        ;;
        *)
            echo "ERROR: Error when searching for user, response is : \"$SEARCH_RESPONSE\""
            exit 1
        ;;
    esac
}

ADMIN_PASS=$(cat /var/run/secrets/opendj-passwords/dirmanager.pw)

AM_STORES_USER_PASSWORD_REAL="userPassword: $AM_STORES_USER_PASSWORD"
AM_STORES_APPLICATION_PASSWORD_REAL="userPassword: $AM_STORES_APPLICATION_PASSWORD"
AM_STORES_CTS_PASSWORD_REAL="userPassword: $AM_STORES_CTS_PASSWORD"

if [ -n "$OLD_AM_STORES_USER_PASSWORD" ] ; then
  AM_STORES_USER_PASSWORD_REAL=$(cat<<EOM
userPassword: $AM_STORES_USER_PASSWORD
userPassword: $OLD_AM_STORES_USER_PASSWORD
EOM
)
fi

if [ -n "$OLD_AM_STORES_APPLICATION_PASSWORD" ] ; then
  AM_STORES_APPLICATION_PASSWORD_REAL=$(cat<<EOM
userPassword: $AM_STORES_APPLICATION_PASSWORD
userPassword: $OLD_AM_STORES_APPLICATION_PASSWORD
EOM
)
fi

if [ -n "$OLD_AM_STORES_CTS_PASSWORD" ] ; then
  AM_STORES_CTS_PASSWORD_REAL=$(cat<<EOM
userPassword: $AM_STORES_CTS_PASSWORD
userPassword: $OLD_AM_STORES_CTS_PASSWORD
EOM
)
fi

chgPass ds-idrepo-0.ds-idrepo ${ADMIN_PASS} 'ou=admins,ou=identities' 'uid=am-identity-bind-account' "${AM_STORES_USER_PASSWORD_REAL}"
chgPass ds-idrepo-0.ds-idrepo ${ADMIN_PASS} 'ou=admins,ou=am-config' 'uid=am-config' "${AM_STORES_APPLICATION_PASSWORD_REAL}"
chgPass ds-cts-0.ds-cts ${ADMIN_PASS} 'ou=admins,ou=famrecords,ou=openam-session,ou=tokens' 'uid=openam_cts' "${AM_STORES_CTS_PASSWORD_REAL}"
echo 'Password script finished'

echo "done"
