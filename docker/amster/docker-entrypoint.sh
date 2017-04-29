#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

DIR=`pwd`

CONFIG_ROOT=${CONFIG_ROOT:-"${DIR}/git"}
#CONFIG_LOCATION=${CONFIG_LOCATION:-"forgeops-init/amster"}
# Path to script location - this is *not* the path to the amster/*.json config files - it is the path
# to  *.amster scripts.
AMSTER_SCRIPTS=${AMSTER_SCRIPTS:-"${DIR}/scripts"}


./git-init.sh

if [ "$?" -ne 0 ]; then 
    echo "git init failed, Can not continue. This container will sleep for ten minutes to allow you exec into the container for debugging"
    sleep 600
    exit 1
fi


pause() {
    echo "Container will now pause. On Kubernetes, you can run the following command to exec into the container"
    echo "kubectl exec amster -it bash "
    while true
    do
        sleep 100000 
    done
}

case $1  in
pause) 
    pause
    ;;
configure)
    ./amster-install.sh
    pause
    ;;
export)
    ./export.sh 
    ;;
*) 
   exec "$@"
esac
