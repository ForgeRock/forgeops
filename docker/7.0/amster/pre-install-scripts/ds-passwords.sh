#!/bin/bash

DS_SERVERS="ds-cts-0.ds-cts ds-idrepo-0.ds-idrepo"

chgPass () {
    local HOST=$1
    local ADMIN_PASS=$2
    local USER_DN=$3
    local USER_PASS=$4
    echo "checking $HOST for $USER_DN"
    CXN="-h $HOST -p 1389 -w $ADMIN_PASS"
    ldapsearch ${CXN} -D "uid=admin" -b $USER_DN  > /dev/null
    SEARCH_RESPONSE=$?
    case "${SEARCH_RESPONSE}" in
        "0")
            echo "changing password of $USER_DN on $HOST"
            ldappasswd ${CXN} -D "uid=admin" -s "${USER_PASS}" "${USER_DN}"
        ;;
        "32")
            echo "${USER_DN} not found, skipping... "
        ;;

        *)
            echo "ERROR: Error when searching for user, response $SEARCH_RESPONSE"
            exit 1
        ;;
    esac
}

chgPass ds-idrepo-0.ds-idrepo ${CFGDIR_PASS} uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens ${CTSUSR_PASS}
chgPass ds-idrepo-0.ds-idrepo ${CFGDIR_PASS} uid=am-identity-bind-account,ou=admins,ou=identities ${USRUSR_PASS}
chgPass ds-idrepo-0.ds-idrepo ${CFGDIR_PASS} uid=am-config,ou=admins,ou=am-config ${CFGUSR_PASS}

chgPass ds-cts-0.ds-cts ${CFGDIR_PASS} uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens ${CTSUSR_PASS}
chgPass ds-cts-0.ds-cts ${CFGDIR_PASS} uid=am-identity-bind-account,ou=admins,ou=identities ${USRUSR_PASS}
chgPass ds-cts-0.ds-cts ${CFGDIR_PASS} uid=am-config,ou=admins,ou=am-config ${CFGUSR_PASS}
