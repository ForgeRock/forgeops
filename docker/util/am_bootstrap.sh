#!/usr/bin/env bash
# This script copies the required bootstrap files for AM. It determines if AM
# is configured already by querying the config store. 
# TODO: Deprecate this when we get boot from json support
set -x

BASE_DN="${BASE_DN:-dc=openam,dc=forgerock,dc=org}"

# Configuration store LDAP. Defaults to the configuration store stateful set running in the same namespace.
CONFIGURATION_LDAP="${CONFIGURATION_LDAP:-configstore-0.configstore:1389}"

# Default path to config store directory manager password file. This is mounted by Kubernetes.
DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE:-/var/run/secrets/configstore/dirmanager.pw}

OPENAM_HOME=${OPENAM_HOME:-/home/forgerock/openam}

# Test the configstore to see if it contains a configuration. Return 0 if configured.
is_configured() {
    echo "Testing if the configuration store is configured with an AM installation"
    test="ou=services,$BASE_DN"
    r=`ldapsearch -y ${DIR_MANAGER_PW_FILE} -A -H "ldap://${CONFIGURATION_LDAP}" -D "cn=Directory Manager" -s base -l 5 -b "$test"  > /dev/null 2>&1`
    status=$?
    echo "Is configured exit status is $status"
    return $status
}

bootstrap() {
    if is_configured;
    then
        echo "Configstore is present. Creating bootstrap"
        mkdir -p "${OPENAM_HOME}/openam"
        cp -L /var/run/openam/*.json "$OPENAM_HOME"
    fi
}

bootstrap