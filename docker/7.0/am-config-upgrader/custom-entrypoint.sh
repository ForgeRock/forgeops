#!/usr/bin/env bash
#
# Copyright 2020 ForgeRock AS. All rights reserved.
#

[ ! -d "/am-config" ] && \
    echo "AM Config Volume mount not present at /am-config." && \
    exit 1
[ ! -d "/am-config/config/services" ] && \
    echo "AM Config directory structure incorrect. Must be /am-config/config/services." && \
    exit 1

"$FORGEROCK_HOME"/amupgrade/amupgrade \
    --inputConfig /am-config/config/services \
    --output /am-config/config/services \
    --fileBasedMode \
    --prettyArrays \
    --clean false \
    --baseDn ou=am-config \
    $(ls -d /rules/*)

sleep 20
