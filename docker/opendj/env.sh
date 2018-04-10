#!/usr/bin/env bash
# Source this to set standard environment variables

# Default number of nodes in the DS cluster.
export DS_SET_SIZE="${DS_SET_SIZE:-1}"

# This should already be set by k8s - but in case it isn't we default it.
export DJ_INSTANCE="${DJ_INSTANCE:-userstore}"

# Subsequent scripts may want to know our FQDN in the cluster. The convention below works in k8s using StatefulSets.
export FQDN="${HOSTNAME}.${DJ_INSTANCE}"

export BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/bak}

# Admin id for replication.
export ADMIN_ID=admin


# The section below calculates the environment variables needed to parameterize the config.ldif file.
let last_ds="$DS_SET_SIZE - 1"

# For each directory server....
for j in $(seq 0 $last_ds); do
    dsrs="${DJ_INSTANCE}-$j.${DJ_INSTANCE}:8989"
    if [ "$j" -eq "0" ]; then
        DS_CHANGELOG_HOSTPORTS="$dsrs"
    else
        DS_CHANGELOG_HOSTPORTS="$DS_CHANGELOG_HOSTPORTS,$dsrs"
    fi
done

export DS_CHANGELOG_HOSTPORTS

#  Selectively enable or disable backends
export DS_ENABLE_USERSTORE=true
export DS_ENABLE_CTS=true

export SERVER_ID=1

# Try to grab the server id from the statefulset hostname
ID="${HOSTNAME: -1}"
# If it is a digit - assume it is the set number.
#
if [[ $ID =~ ^-?[0-9]+$ ]]; then
  # server id can not start at 0
  export SERVER_ID=$(expr "$ID" + 10 )
fi
