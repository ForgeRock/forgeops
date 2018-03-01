#!/usr/bin/env bash
# Source this to set standard environment variables

# This should already be set by k8s - but in case it isn't we default it.
export DJ_INSTANCE="${DJ_INSTANCE:-userstore}"

# Subsequent scripts may want to know our FQDN in the cluster. The convention below works in k8s using StatefulSets.
FQDN="${HOSTNAME}.${DJ_INSTANCE}"

if echo $HOSTNAME | grep "\-rs" ; then
    FQDN="${HOSTNAME}.${DJ_INSTANCE}-rs"
fi

if echo $HOSTNAME | grep "\-admin" ; then
    FQDN="${HOSTNAME}.${DJ_INSTANCE}-admin"
fi

export FQDN

# If we are an RS, our fqdn has a suffix of -rs
#export RS_FQDN="${HOSTNAME}.${DJ_INSTANCE}-rs"
# FQDN of the admin server. There is only one admin server - so we can default it to first instance (-0)
# Note that *within* the admin server it finds itself using $DJ_FQDN. This is env var is for *DS* nodes to
# to reference the admin server is/
# todo: Do we actually need this at all?
#export ADMIN_FQDN="${DJ_INSTANCE}-admin-0.${DJ_INSTANCE}-admin"

# Default bootstrap script
BOOTSTRAP=${BOOTSTRAP:-/opt/opendj/bootstrap/setup.sh}

export INSTANCE_ROOT=/opt/opendj/data

DB_NAME=${DB_NAME:-userRoot}

# The type of DJ we want to bootstrap. This determines the LDIF files and scripts to load. Defaults to a userstore.
BOOTSTRAP_TYPE="${BOOTSTRAP_TYPE:-userstore}"


# If a password file is mounted, grab the password from that, otherwise default
if [ ! -r "$DIR_MANAGER_PW_FILE" ]; then
    echo "Warning; Can't find path to $DIR_MANAGER_PW_FILE. I will create a default DJ admin password"
    mkdir -p "$SECRET_PATH"
    echo -n "password" > "$DIR_MANAGER_PW_FILE"
fi


# utility functions

# Run setup as a directory server/
setup_ds() {
    INIT_OPTION="--addBaseEntry"

    # If NUMBER_SAMPLE_USERS is set AND we are the first node, then generate sample users.
    if [[  -n "${NUMBER_SAMPLE_USERS}" && $HOSTNAME = *"0"* ]]; then
        INIT_OPTION="--sampleData ${NUMBER_SAMPLE_USERS}"
    fi


    # An admin server is also a directory server.
    /opt/opendj/setup directory-server -p 1389 --ldapsPort 1636 --enableStartTLS  \
      --adminConnectorPort 4444 \
      --instancePath ./data \
      --baseDN "${BASE_DN}" -h "${FQDN}" \
      --rootUserPasswordFile "${DIR_MANAGER_PW_FILE}" \
      --acceptLicense \
      ${INIT_OPTION} || (echo "Setup failed, will sleep for debugging"; sleep 10000)
}

# Load any optional LDIF files
load_ldif() {
    # If any optional LDIF files are present, load them.
    ldif="bootstrap/${BOOTSTRAP_TYPE}/ldif"

    if [ -d "$ldif" ]; then
        echo "Loading LDIF files in $ldif"
        for file in "${ldif}"/*.ldif;  do
            echo "Loading $file"
            # search + replace all placeholder variables. Naming conventions are from AM.
            sed -e "s/@BASE_DN@/$BASE_DN/"  \
                -e "s/@userStoreRootSuffix@/$BASE_DN/"  \
                -e "s/@DB_NAME@/$DB_NAME/"  \
                -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/"  <${file}  >/tmp/file.ldif

            ./bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -j ${DIR_MANAGER_PW_FILE} -f /tmp/file.ldif
          echo "  "
        done
    fi
}

# Run any post installation scripts for the bootstrap type.
post_install_scripts() {
    script="bootstrap/${BOOTSTRAP_TYPE}/post-install.sh"

    if [ -r "$script" ]; then
        echo "executing post install script $script"
        sh "$script"
    fi
}