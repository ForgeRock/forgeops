#!/usr/bin/env sh
# Default setup script
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
set -x

echo "Setting up default OpenDJ instance."

cd /opt/opendj

touch /opt/opendj/BOOTSTRAPPING
source /opt/opendj/env.sh


# The role of this server. Role can be replication-server, directory-server or proxy-server
# If not set, we default to directory-server
DS_ROLE=${DS_ROLE:-"directory-server"}

case "$DS_ROLE" in
directory-server)
    ./bootstrap/setup-directory.sh
    ;;
replication-server)
    ./bootstrap/setup-rs.sh
    ;;
*)
    echo "Unsupported DS Role $DS_ROLE"
    exit 1
esac


./bootstrap/log-redirect.sh


# Common tasks for all roles...
# This enables the Prometheus metrics server
bin/dsconfig  -h localhost -p 4444 -D "cn=directory manager" \
    -w ${PASSWORD} --trustAll --no-prompt --batch <<EOF
create-connection-handler --type http --handler-name "HTTP Connection Handler" --set enabled:true --set listen-port:8081
set-http-endpoint-prop --endpoint-name /metrics/prometheus --set authorization-mechanism:HTTP\ Anonymous
EOF


