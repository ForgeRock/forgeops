#!/usr/bin/env bash
# Redirects the logging output for the container to stdout.
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#

source /opt/opendj/env.sh


echo "Redirecting logs to stdout"

set -x

# We disable this logger.  By default errors already go to stderr.
/opt/opendj/bin/dsconfig set-log-publisher-prop \
          --publisher-name "File-Based Error Logger" \
          --set log-file:/dev/stdout \
          --set enabled:false \
          --reset rotation-policy \
          --hostname  localhost  \
          --port 4444 \
          --bindDn "cn=Directory Manager" \
          --bindPasswordFile "${DIR_MANAGER_PW_FILE}" \
          --trustAll \
          --no-prompt

/opt/opendj/bin/dsconfig set-log-publisher-prop \
          --publisher-name "Replication Repair Logger" \
          --set log-file:/dev/stdout \
          --reset rotation-policy \
          --hostname localhost \
          --port 4444 \
          --bindDn "cn=Directory Manager" \
          --bindPasswordFile "${DIR_MANAGER_PW_FILE}" \
          --trustAll \
          --no-prompt
