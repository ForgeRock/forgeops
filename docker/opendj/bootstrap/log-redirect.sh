#!/usr/bin/env bash
# Redirects the logging output for the container to stdout.
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#


echo "Redirecting logs to stdout"

set -x

# Disable the default file based error logger as the messages go to stdout by default.
/opt/opendj/bin/dsconfig set-log-publisher-prop \
          --publisher-name "File-Based Error Logger" \
          --set log-file:/dev/stdout \
          --set enabled:false \
          --reset rotation-policy \
          --offline \
          --no-prompt

/opt/opendj/bin/dsconfig set-log-publisher-prop \
          --publisher-name "Replication Repair Logger" \
          --set log-file:/dev/stdout \
          --reset rotation-policy \
          --offline \
          --no-prompt
