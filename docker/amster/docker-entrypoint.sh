#!/usr/bin/env bash
#
# Copyright (c) 2016-2017 ForgeRock AS. All rights reserved.
#

set -x


exit_script() {
    echo "Got signal. Killing child processes"
    trap - SIGINT SIGTERM # clear the trap
    kill -- -$$ # Sends SIGTERM to child/sub processes
    echo "Exiting"
    exit 0
}

trap exit_script SIGINT SIGTERM SIGUSR1 EXIT



pause() {
    echo "Args are $# "

    echo "Container will now pause. You can use kubectl exec to run export.sh"
    # Sleep forever, waiting for someone to exec into the container.
    while true
    do
        sleep 1000000 & wait
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
