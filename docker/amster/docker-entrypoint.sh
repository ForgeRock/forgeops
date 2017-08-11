#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

set -x
DIR=`pwd`

CONFIG_ROOT=${CONFIG_ROOT:-"${DIR}/git"}
# Path to script location - this is *not* the path to the amster/*.json config files - it is the path
# to  *.amster scripts.
AMSTER_SCRIPTS=${AMSTER_SCRIPTS:-"${DIR}/scripts"}


pause() {
    echo "Args are $# "
    echo "Container will now pause. You can use kubectl exec to run export.sh"
    # Sleep forever, waiting for someone to exec into the container.
    while true
    do
        sleep 1000000
    done
}

# Default path to config store directory manager password file. This is mounted by Kube.
DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE:-/var/run/secrets/configstore/dirmanager.pw}

# Wait until the configuration store comes up. This function will not return until it is up.
wait_configstore_up() {
    echo "Waiting for the configuration store to come up"
    while true 
    do
        ldapsearch -y ${DIR_MANAGER_PW_FILE} -H ldap://configstore-0.configstore:1389 -D "cn=Directory Manager" -s base -l 5 > /dev/null 2>&1
        if [ $? = 0 ]; 
        then
            echo "Config store is up"
            break;
        fi
        sleep 5
        echo -n "."
    done
}

# Test the configstore to see if it contains a configuration. Return 0 if configured.
is_configured() {
    echo "Testing if the configuration store is configured with an AM installation"
    test="ou=services,dc=openam,dc=forgerock,dc=org"
    r=`ldapsearch -y ${DIR_MANAGER_PW_FILE} -A -H ldap://configstore-0.configstore:1389 -D "cn=Directory Manager" -s base -l 5 -b "$test"  > /dev/null 2>&1`
    status=$?
    echo "Is configured exit status is $status"
    return $status
}

export OPENAM_HOME=/home/forgerock/openam


copy_secrets() {
    echo "Copying secrets"
    cp  -L /var/run/secrets/openam/.keypass "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/.storepass "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/keystore.jceks "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/keystore.jks "${OPENAM_HOME}/openam"
    cp -L /var/run/secrets/openam/authorized_keys "$OPENAM_HOME"
}

# This function is called as the init container that runs before OpenAM. It Checks the configstore. If it is configured,
# This function will create the AM bootstrap file. Otherwise AM will come up in install mode.
# Revisit when AME-13657 is fixed.
bootstrap_openam() {
    wait_configstore_up
    is_configured
    if [ $? = 0 ];
    then
        echo "Configstore is present. Creating bootstrap"
        mkdir -p "${OPENAM_HOME}/openam"
        cp -L /var/boot/*.json "$OPENAM_HOME"
        copy_secrets
    fi
    exit 0
}

case $1  in
bootstrap) 
    bootstrap_openam
    ;;
pause) 
    pause
    ;;
configure)
    # invoke amster install.
    ./amster-install.sh
    pause
    ;;
export)
    ./export.sh
    ;;
*) 
   exec "$@"
esac
