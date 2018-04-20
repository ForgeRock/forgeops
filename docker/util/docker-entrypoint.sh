#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

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

case "$command"  in
bootstrap) 
    exec $HOME/am_bootstrap.sh
    ;;
wait)
    # execute wait_for script that waits for a service, pod, etc. to be ready.
    shift
    exec $HOME/wait_for_service.sh "$@"
    ;;
pause) 
    pause
    ;;
*) 
   exec "$@"
esac



