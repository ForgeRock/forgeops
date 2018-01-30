#!/usr/bin/env bash
# Source this to set standard environment variables


# Subsequent scripts may want to know our FQDN in the cluster. This works on Kubernetes.
export DJ_FQDN="${HOSTNAME}.${DJ_INSTANCE}"
# If we are an RS, our hostname is different
export RS_FQDN="${HOSTNAME}.${DJ_INSTANCE_RS}"

# Default bootstrap script
BOOTSTRAP=${BOOTSTRAP:-/opt/opendj/bootstrap/setup.sh}


# Set a default base DN. Setup scripts can choose to override this.
# If a password file is mounted, grab the password from that, otherwise default
if [ ! -r "$DIR_MANAGER_PW_FILE" ]; then
    echo "Warning; Can't find path to $DIR_MANAGER_PW_FILE. I will create a default DJ admin password"
    mkdir -p "$SECRET_PATH"
    echo -n "password" > "$DIR_MANAGER_PW_FILE"
fi

export PASSWORD=`cat $DIR_MANAGER_PW_FILE`

export INSTANCE_ROOT=/opt/opendj/data
