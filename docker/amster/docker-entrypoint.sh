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

    if [ -x /opt/forgerock/frconfigsrv ]; then
        echo "Running frconfig"
        /opt/forgerock/frconfigsrv
    fi

    echo "Container will now pause. You can use kubectl exec to run export.sh"
    # Sleep forever, waiting for someone to exec into the container.
    while true
    do
        sleep 1000000
    done
}


case $1  in
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
