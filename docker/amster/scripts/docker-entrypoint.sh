#!/usr/bin/env bash
#
# Copyright (c) 2016-2017 ForgeRock AS. All rights reserved.
#
set -e

# If a command arg is not passed, default to import
ACTION="${1:-import}"

echo "amster action is $ACTION"

# Default is to connect via the internal http service name
# Note we use AMSTER_AM_URL so we don't collide with the platform AM_URL - which might be external
export AMSTER_AM_URL=${AMSTER_AM_URL:-http://am:80/am}

pause() {
    echo "Args are $# "

    echo "Container will now pause. You can exec into the container using kubectl exec to run export.sh"
    # Sleep forever, waiting for someone to exec into the container.
    while true
    do
        sleep 1000000 & wait
    done
}


# Extract amster version for commons parameter to modify configs
echo "Extracting amster version"
VER=$(./amster --version)
echo "Amster version output is: '${VER}'"
[[ "$VER" =~ ([0-9].[0-9].[0-9](\.[0-9]*)?-([a-zA-Z0-9]+|([-a-zA-Z0-9]+)?SNAPSHOT|RC[0-9]+|M[0-9]+)|[0-9].[0-9].[0-9](\.[0-9]*)?) ]]
VERSION=${BASH_REMATCH[1]}
echo "Amster version is: '${VERSION}'"
export VERSION

case $ACTION  in
pause)
    pause
    ;;
export)
    # invoke amster export
    ./export.sh ${TYPE}
    ;;
import)
    # invoke amster install.
    ./import.sh
    ;;
upload)
    # Like import - but waits for files to be uploaded to config/upload
    ./import.sh upload
    ;;
*)
   exec "$@"
esac
