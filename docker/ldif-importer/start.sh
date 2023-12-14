#!/usr/bin/env bash

# Checking DS is up

wait_repo() {
    REPO="$1-0.$1"
    echo "Waiting for $REPO to be available. Trying /alive endpoint"
    while [[ "$(wget --server-response $REPO:8080/alive --spider 2>&1 | awk '/^  HTTP/{print $2}')" != "200" ]];
    do
            sleep 5;
    done
    echo "$REPO is responding"
}

# Check whether deployment is CDK or CDM
size=$FORGEOPS_PLATFORM_SIZE

wait_repo ds-idrepo

# Wait for cts server to be ready when deploying CDM
if [[ "$size" != "cdk" ]]; then 
    wait_repo ds-cts
fi


# Set the DS passwords for each store
if [ -f "/opt/opendj/ds-passwords.sh" ]; then
    echo "Setting directory service account passwords"
    /opt/opendj/ds-passwords.sh $size
    if [ $? -ne 0 ]; then
        echo "ERROR: Pre install script failed"
        exit 1
    fi
fi

