#!/usr/bin/env sh
# Default setup script
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#set -x

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

./bootstrap/setup-metrics.sh

# Before we enable rest2ldap we need a strategy for paramterizing the json template
#./bootstrap/setup-rest2ldap.sh


