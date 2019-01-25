#!/usr/bin/env bash
# This script copies the required bootstrap files for AM. It determines if AM
# is configured already by querying the config store. 
# TODO: Deprecate this when we get boot from json support
set -x

BASE_DN="${BASE_DN:-ou=am-config}"

# Configuration store LDAP. Defaults to the configuration store stateful set running in the same namespace.
CONFIGURATION_LDAP="${CONFIGURATION_LDAP:-configstore-0.configstore:1389}"

# Default path to config store directory manager password file. This is mounted by Kubernetes.
DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE:-/var/run/secrets/configstore/dirmanager.pw}

OPENAM_HOME=${OPENAM_HOME:-/home/forgerock/openam}
# Context root
OPENAM_CTX=am
AM_CTX="${OPENAM_HOME}/${OPENAM_CTX}"

# Test the configstore to see if it contains a configuration. Return 0 if configured.
is_configured() {
    echo "Testing if the configuration store is configured with an AM installation"
    test="ou=services,$BASE_DN"
    r=`ldapsearch -y ${DIR_MANAGER_PW_FILE} -A -H "ldap://${CONFIGURATION_LDAP}" -D "cn=Directory Manager" -s base -l 5 -b "$test"  > /dev/null 2>&1`
    status=$?
    echo "Is configured exit status is $status"
    return $status
}

# Note - because AM is installed at the context root (ROOT/) it impacts
# the location of bootstrap and keystore files (the context is used in forming the path)
# If you ever change the am context (not recommended), you need to copy these files to OPENAM_HOME/$context
copy_secrets() {
    echo "Copying secrets"
    mkdir -p "${AM_CTX}"
    cp  -L /var/run/secrets/openam/.keypass "${AM_CTX}"
    cp  -L /var/run/secrets/openam/.storepass "${AM_CTX}"
    cp  -L /var/run/secrets/openam/keystore.jceks "${AM_CTX}"
    cp  -L /var/run/secrets/openam/keystore.jks "${AM_CTX}"
    cp  -L /var/run/secrets/openam/authorized_keys "$OPENAM_HOME"
    cp  -L /var/run/secrets/openam/openam_mon_auth "${AM_CTX}"
    # The new AM secrets API specifies a directory for password secrets. Each file is a key, and the contents are the secret value
    # You can NOT use a leading dot 
    # In your global -> Secret Stores -> default-password-store - configure /home/forgerock/openam/secrets as your Directory
    mkdir -p "${OPENAM_HOME}/secrets"
    cp -L /var/run/secrets/openam/.keypass "${OPENAM_HOME}/secrets/entrypass"
    cp -L /var/run/secrets/openam/.storepass "${OPENAM_HOME}/secrets/storepass"
}

bootstrap() {
    if is_configured;
    then
        echo "Configstore is present. Copying bootstrap"
        cp -L /var/run/openam/*.json "$OPENAM_HOME"
    fi
}

copy_secrets
bootstrap