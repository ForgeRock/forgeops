#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

DIR=`pwd`

CONFIG_ROOT=${CONFIG_ROOT:-"${DIR}/git"}
# Path to script location - this is *not* the path to the amster/*.json config files - it is the path
# to  *.amster scripts.
AMSTER_SCRIPTS=${AMSTER_SCRIPTS:-"${DIR}/scripts"}


pause() {
    echo "Args are $# "
    echo "Container will now pause. You can use kubectl exec to inspect this container"
    if [ "$#" -gt 0 ];
    then
        echo "Will perform periodic export of AM config"
        ./export.sh $1
    fi
    # Else - we just sleep forever, waiting for someone to exec into the container
    while true
    do
        sleep 100000 
    done
}

# Default path to config store directory manager password file. This is mounted by Kube.
DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE:-/var/secrets/configstore/dirmanager.pw}

# Wait until the configuration store comes up. This function will not return until it is up.
wait_configstore_up() {
    echo "Waiting for the configuration store to come up"
    while true 
    do
        ldapsearch -y ${DIR_MANAGER_PW_FILE} -H ldap://configstore-0.configstore:1389 -D "cn=Directory Manager" -s base -l 5
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
    r=`ldapsearch -y ${DIR_MANAGER_PW_FILE} -A -H ldap://configstore-0.configstore:1389 -D "cn=Directory Manager" -s base -l 5 -b "$test"`
    status=$?
    echo "Result is $r status is $status"
    return $status
}

OPENAM_HOME=/home/forgerock/openam

# This function is called as the init container that runs before OpenAM. It Checks the configstore. If it is configured,
# This function will create the AM bootstrap file. Otherwise AM will come up in install mode.
# Revisit when AME-13657 is fixed.
bootstrap_openam() {
    wait_configstore_up
    is_configured
    if [ $? = 0 ];
    then
        echo "Configstore is present. Creating bootstrap"
        mkdir -p "$OPENAM_HOME"/openam/debug; 
        cd "$OPENAM_HOME"
        cp -L /var/boot/*.json "$OPENAM_HOME"
        cp  -rL /var/secrets/openam/.?* openam
        cp -L /var/secrets/openam/authorized_keys "$OPENAM_HOME"
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
    shift
    pause $*
    ;;
export)
    ./export.sh $2
    ;;
*) 
   exec "$@"
esac
