#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

set -x

pause() {
    echo "Args are $# "

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
