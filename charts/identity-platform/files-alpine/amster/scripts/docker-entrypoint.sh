#!/bin/sh
#
# Copyright 2024 Ping Identity Corporation. All Rights Reserved
# This code is to be used exclusively in connection with Ping Identity
# Corporation software or services. Ping Identity Corporation only offers
# such software or services to legal entities who have entered into a
# binding license agreement with Ping Identity Corporation.
#
# POSIX (busybox ash) variant of files/amster/scripts/docker-entrypoint.sh:
# the alpine amster image has no bash. See the bash version for the full
# action documentation.
set -e

# If a command arg is not passed, default to import
ACTION="${1:-import}"

echo "amster action is $ACTION"

# Default is to connect via the internal http service name
# Note we use AMSTER_AM_URL so we dont collide with the platform AM_URL - which might be external
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

# Extract amster version for commons parameter to modify configs.
# The bash variant uses BASH_REMATCH on ./amster --version output; busybox
# ash has no bash regex capture, so pull the first version-looking token
# with sed. The first match wins (amster prints e.g. "9.0.0" or
# "9.0.0-SNAPSHOT" with a build id on the same or a later line).
echo "Extracting amster version"
VER=$(./amster --version)
echo "Amster version output is: '${VER}'"
VERSION=$(printf '%s' "$VER" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?(-([a-zA-Z0-9]+|[-a-zA-Z0-9]+SNAPSHOT|RC[0-9]+|M[0-9]+))?' | head -n 1)
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
