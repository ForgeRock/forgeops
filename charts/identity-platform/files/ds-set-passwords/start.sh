#!/usr/bin/env bash

# Checking PingDS is up

wait_repo() {
    local HOST="$1-0.$1"
    local USER_DN=$2
    local USER_UID=$3
    local CXN="-h ${HOST} -p 1636 --useSsl --trustAll"
    echo "Waiting for $HOST to be available."
    SEARCH_CMD="ldapsearch ${CXN} -D 'uid=admin' -w '${ADMIN_PASS}' -b ${USER_DN} '${USER_UID}'"
    eval $SEARCH_CMD
    SEARCH_REPONSE=$?
    while [[ "$SEARCH_RESPONSE" != "0" ]] ; do
        sleep 5;
        eval $SEARCH_CMD
        SEARCH_RESPONSE=$?
    done
    echo "$REPO is responding"
}

ADMIN_PASS=$(cat /var/run/secrets/opendj-passwords/dirmanager.pw)

wait_repo ds-idrepo ou=admins,ou=identities "uid=am-identity-bind-account" 
wait_repo ds-cts ou=admins,ou=famrecords,ou=openam-session,ou=tokens "uid=openam_cts" 

# Set the PingDS passwords for each store
if [ -f "/opt/opendj/ds-passwords.sh" ]; then
    echo "Setting directory service account passwords"
    /opt/opendj/ds-passwords.sh
    if [ $? -ne 0 ]; then
        echo "ERROR: Pre install script failed"
        exit 1
    fi
fi
