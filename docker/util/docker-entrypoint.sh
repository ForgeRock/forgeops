#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

set -x
DIR=`pwd`


command=$1

echo "Command: $command"

pause() {
    echo "Container will now pause"
    # Sleep forever, waiting for someone to exec into the container.
    while true
    do
        sleep 1000000
    done
}




copy_secrets() {
    echo "Copying secrets"
    mkdir -p "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/.keypass "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/.storepass "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/keystore.jceks "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/keystore.jks "${OPENAM_HOME}/openam"
    cp  -L /var/run/secrets/openam/authorized_keys "$OPENAM_HOME"
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
#copy_secrets


# The default command is "run" - which assumes an external configuration store. If
# you want AM to come up without waiting for a configuration store, use run-nowait.
case "$command"  in
bootstrap) 
    exec $HOME/am_bootstrap.sh
    ;;
pause) 
    pause
    ;;
*) 
   exec "$@"
esac



