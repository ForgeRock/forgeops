#!/bin/bash

chgPass () {
    local HOST=$1
    local ADMIN_PASS=$2
    local USER_DN=$3
    local USER_UID=$4
    local USER_PASS=$5
    echo "checking $HOST for $USER_DN $USER_UID"
    CXN="-h $HOST -p 1389 -w $ADMIN_PASS"
    ldapsearch ${CXN} -D "uid=admin" -b $USER_DN "${USER_UID}"  > /dev/null
    SEARCH_RESPONSE=$?
    case "${SEARCH_RESPONSE}" in
        "0")
            local FULL_USER_DN="${USER_UID},${USER_DN}"
            echo "changing password of $FULL_USER_DN on $HOST"
            ldappasswordmodify ${CXN} -D "uid=admin" -a "dn:${FULL_USER_DN}" -n "${USER_PASS}"
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

chgPass ds-idrepo-0.ds-idrepo ${CFGDIR_PASS} ou=admins,ou=famrecords,ou=openam-session,ou=tokens "uid=openam_cts" ${CTSUSR_PASS}
chgPass ds-idrepo-0.ds-idrepo ${CFGDIR_PASS} ou=admins,ou=identities "uid=am-identity-bind-account" ${USRUSR_PASS}
chgPass ds-idrepo-0.ds-idrepo ${CFGDIR_PASS} ou=admins,ou=am-config "uid=am-config" ${CFGUSR_PASS}

chgPass ds-cts-0.ds-cts ${CFGDIR_PASS} ou=admins,ou=famrecords,ou=openam-session,ou=tokens "uid=openam_cts" ${CTSUSR_PASS}
chgPass ds-cts-0.ds-cts ${CFGDIR_PASS} ou=admins,ou=identities "uid=am-identity-bind-account" ${USRUSR_PASS}
chgPass ds-cts-0.ds-cts ${CFGDIR_PASS} ou=admins,ou=am-config "uid=am-config" ${CFGUSR_PASS}
