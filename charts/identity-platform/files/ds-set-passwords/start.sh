#!/usr/bin/env bash

# Checking the dirmanager.pw is available before proceeding, as it is required to set the passwords for the PingDS accounts
wait_dirmanager_pw() {
    local max_retries=10
    local retry_count=0
    while [ ! -f /var/run/secrets/opendj-passwords/dirmanager.pw ]; do
        if [ "$retry_count" -ge "$max_retries" ]; then
            echo "ERROR: dirmanager.pw secret not available after ${max_retries} retries. Exiting."
            exit 1
        fi
        echo "Waiting for dirmanager.pw secret to be mounted..."
        sleep 5
        retry_count=$((retry_count + 1))
    done
    echo "dirmanager.pw is available"
}

# Checking PingDS is up
wait_repo() {
    local HOST="$1-0.$1"
    local USER_DN=$2
    local USER_UID=$3
    local CXN="-h ${HOST} -p 1636 --useSsl --trustAll"
    echo "Waiting for $HOST to be available."
    SEARCH_CMD="ldapsearch ${CXN} -D 'uid=admin' -w '${ADMIN_PASS}' -b ${USER_DN} '${USER_UID}'"
    eval $SEARCH_CMD
    SEARCH_RESPONSE=$?
    while [[ "$SEARCH_RESPONSE" != "0" ]] ; do
        sleep 5;
        eval $SEARCH_CMD
        SEARCH_RESPONSE=$?
    done
    echo "$HOST is responding"
}

wait_dirmanager_pw

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
