#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

set -x
DIR=`pwd`


command=$1

echo "Command: $command"

# Configuration store LDAP. Defaults to the configuration store stateful set running in the same namespace.
export CONFIGURATION_LDAP="${CONFIGURATION_LDAP:-configstore-0.configstore:1389}"

# Optional AM web app customization script that can be run before Tomcat starts.
CUSTOMIZE_AM="${CUSTOMIZE_AM:-/home/forgerock/customize-am.sh}"

pause() {
    echo "Container will now pause"
    # Sleep forever, waiting for someone to exec into the container.
    while true
    do
        sleep 1000000
    done
}

# Default path to config store directory manager password file. This is mounted by Kubernetes.
DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE:-/var/run/secrets/configstore/dirmanager.pw}

# Wait until the configuration store comes up. This function will not return until it is up.
wait_configstore_up() {
    echo "Waiting for the configuration store to come up"
    while true 
    do
        ldapsearch -y ${DIR_MANAGER_PW_FILE} -H "ldap://${CONFIGURATION_LDAP}" -D "cn=Directory Manager" -s base -l 5 > /dev/null 2>&1
        if [ $? = 0 ]; 
        then
            echo "Configuration store is up"
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
    r=`ldapsearch -y ${DIR_MANAGER_PW_FILE} -A -H "ldap://${CONFIGURATION_LDAP}" -D "cn=Directory Manager" -s base -l 5 -b "$test"  > /dev/null 2>&1`
    status=$?
    echo "Is configured exit status is $status"
    return $status
}

export OPENAM_HOME=${OPENAM_HOME:-/home/forgerock/openam}


copy_secrets() {
    echo "Copying secrets"
    mkdir -p "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/.keypass "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/.storepass "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/keystore.jceks "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/keystore.jks "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/authorized_keys "$OPENAM_HOME"
}

# This function runs before AM starts. It waits for the config store to be available. If it is configured,
# it will create the AM bootstrap file to point at that config store. Otherwise AM will come up in install mode.
# Revisit when AME-13657 is fixed.
bootstrap_openam() {
    wait_configstore_up
    is_configured
    if [ $? = 0 ];
    then
        echo "Configstore is present. Creating bootstrap"
        mkdir -p "${OPENAM_HOME}/openam"
        cp -L /var/run/openam/*.json "$OPENAM_HOME"
    fi
}

run() {
   if [ -x "${CUSTOMIZE_AM}" ]; then
        echo "Executing AM customization script"
        sh "${CUSTOMIZE_AM}"
   else
        echo "No AM customization script found, so no customizations will be performed"
   fi

    cd "${CATALINA_HOME}"
    exec "${CATALINA_HOME}/bin/catalina.sh" run
}


# Pre-create our keystores for AM.
copy_secrets


# The default command is "run" - which assumes an external configuration store. If
# you want AM to come up without waiting for a configuration store, use run-nowait.
case "$command"  in
bootstrap) 
    bootstrap_openam
    ;;
pause) 
    pause
    ;;
run-nowait)
    run
    ;;
run)
    bootstrap_openam
    run
    ;;
*) 
   exec "$@"
esac
