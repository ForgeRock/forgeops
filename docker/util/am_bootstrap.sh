#!/usr/bin/env bash
set -x

# Configuration store LDAP. Defaults to the configuration store stateful set running in the same namespace.
CONFIGURATION_LDAP="${CONFIGURATION_LDAP:-configstore-0.configstore:1389}"



# Default path to config store directory manager password file. This is mounted by Kubernetes.
DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE:-/var/run/secrets/configstore/dirmanager.pw}

OPENAM_HOME=${OPENAM_HOME:-/home/forgerock/openam}

# Test the configstore to see if it contains a configuration. Return 0 if configured.
is_configured() {
    echo "Testing if the configuration store is configured with an AM installation"
    test="ou=services,dc=openam,dc=forgerock,dc=org"
    r=`ldapsearch -y ${DIR_MANAGER_PW_FILE} -A -H "ldap://${CONFIGURATION_LDAP}" -D "cn=Directory Manager" -s base -l 5 -b "$test"  > /dev/null 2>&1`
    status=$?
    echo "Is configured exit status is $status"
    return $status
}



copy_secrets() {
    echo "Copying secrets"
    mkdir -p "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/.keypass "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/.storepass "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/keystore.jceks "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/keystore.jks "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/authorized_keys "$OPENAM_HOME"
    cp  -L /var/run/secrets/openam/openam_mon_auth "${OPENAM_HOME}/openam"
}


bootstrap() {
    is_configured
    if [ $? = 0 ];
    then
        echo "Configstore is present. Creating bootstrap"
        mkdir -p "${OPENAM_HOME}/openam"
        cp -L /var/run/openam/*.json "$OPENAM_HOME"
    fi
}


copy_secrets
bootstrap

ls -lR $HOME
