#!/usr/bin/env bash
# Source this to set standard environment variables

# Default number of nodes in the DS cluster.
export DS_SET_SIZE="${DS_SET_SIZE:-1}"

# This should already be set by k8s - but in case it isn't we default it.
export DJ_INSTANCE="${DJ_INSTANCE:-userstore}"

# Subsequent scripts may want to know our FQDN in the cluster. The convention below works in k8s using StatefulSets.
export FQDN="${HOSTNAME}.${DJ_INSTANCE}"

# The FQDN of the first server in the statefulset. This is useful for backup or other commands that need to run on the first server.
export  FQDN_DS_0=${DJ_INSTANCE}-0.${DJ_INSTANCE}

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


# Some commands want a directory instance installed, even if they are remote.
# See https://bugster.forgerock.org/jira/browse/OPENDJ-5113 
quick_setup() 
{
    if [ ! -d data/db ]; then
    # backup wants a local directory server installed - even if it is talking to a remote node.
    echo "Creating a skeleton ds instance"
    /opt/opendj/setup directory-server\
        -p 1389 \
        --adminConnectorPort 4444 \
        --baseDN "${BASE_DN}" -h "${FQDN}" \
        --rootUserPasswordFile "${DIR_MANAGER_PW_FILE}" \
        --doNotStart \
        --acceptLicense || (echo "Setup failed, will sleep for debugging"; sleep 10000)

        # also need to create a o=cts backend for the verify process.
        /opt/opendj/bin/dsconfig create-backend \
          --set base-dn:o=cts \
          --set enabled:true \
          --type je \
          --backend-name ctsRoot \
          --offline \
          --no-prompt

    fi
}
