#!/usr/bin/env bash
# Default setup script
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#set -x

echo "Setting up default OpenDJ instance."


# Default bootstrap script
export BOOTSTRAP=${BOOTSTRAP:-/opt/opendj/bootstrap/setup.sh}
export DB_NAME=${DB_NAME:-userRoot}

# The type of DJ we want to bootstrap. This determines the LDIF files and scripts to load. Defaults to a userstore.
export BOOTSTRAP_TYPE="${BOOTSTRAP_TYPE:-userstore}"


cd /opt/opendj

touch /opt/opendj/BOOTSTRAPPING
source /opt/opendj/env.sh


./bootstrap/setup-directory.sh

./bootstrap/log-redirect.sh

./bootstrap/setup-metrics.sh

# rebuild indexes
/opt/opendj/scripts/rebuild.sh


# Before we enable rest2ldap we need a strategy for parameterizing the json template
#./bootstrap/setup-rest2ldap.sh

bin/stop-ds

echo "Moving mutable directories to data/"

mkdir -p data

# For now we need to most of the directories created by setup, including the "immutable" ones.
# When we get full support for commons configuration we should revisit.
for dir in db changelogDb config var
do
    echo "moving $dir to data/"
    # Use cp as it works across file systems.
    cp -r $dir data/$dir
    rm -fr $dir
done




