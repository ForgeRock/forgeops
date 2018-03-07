#!/usr/bin/env bash
# Source this to set standard environment variables

# This should already be set by k8s - but in case it isn't we default it.
export DJ_INSTANCE="${DJ_INSTANCE:-userstore}"

# Subsequent scripts may want to know our FQDN in the cluster. The convention below works in k8s using StatefulSets.
export FQDN="${HOSTNAME}.${DJ_INSTANCE}"

export INSTANCE_ROOT=/opt/opendj/data

export BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/backup}


# If a password file is mounted, grab the password from that, otherwise default
if [ ! -r "$DIR_MANAGER_PW_FILE" ]; then
    echo "Warning; Can't find path to $DIR_MANAGER_PW_FILE. I will create a default DJ admin password"
    mkdir -p "$SECRET_PATH"
    echo -n "password" > "$DIR_MANAGER_PW_FILE"
fi


# utility functions

