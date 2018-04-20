#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS
#

set -x

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



