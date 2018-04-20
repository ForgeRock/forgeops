#!/usr/bin/env bash
# Default setup script
#
# Note that the default install creates *two* backends: o=cts and o=userstore
# Most installs will choose to use one or the other backend depending on the purpose of the instance.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#set -x

echo "Setting up default OpenDJ instance."


# Default bootstrap script
export BOOTSTRAP=${BOOTSTRAP:-/opt/opendj/bootstrap/setup.sh}
export DB_NAME=${DB_NAME:-userRoot}

# We explictly set the OPENDJ_JAVA_ARGS hence overriding what is set by the configMap because
# for setup we don't need a large heap size
export OPENDJ_JAVA_ARGS="-Xms256m -Xmx512m"

# The type of DJ we want to bootstrap. This determines the LDIF files and scripts to load. Defaults to a directory-server.
# Currently the other allowable value here is proxy.
export BOOTSTRAP_TYPE="${BOOTSTRAP_TYPE:-directory-server}"


cd /opt/opendj

touch /opt/opendj/BOOTSTRAPPING

if [ "${BOOTSTRAP_TYPE}" == "proxy" ]
then
	./bootstrap/setup-proxy.sh
else
	./bootstrap/setup-directory.sh

    echo "Rebuilding indexes"
    bin/rebuild-index --offline --baseDN "${BASE_DN}" --rebuildDegraded
    bin/rebuild-index --offline --baseDN "o=cts" --rebuildDegraded

 fi

# Run post install customization script if the user supplied one.
script="bootstrap/post-install.sh"

if [ -r "$script" ]; then
    echo "executing post install script $script"
    sh "$script"
fi

./scripts/log-redirect.sh


# Before we enable rest2ldap we need a strategy for parameterizing the json template
#./bootstrap/setup-rest2ldap.sh

# Note that presently dsreplication does not handle templated config.ldif. You
# must completely finish setting up replication first, and then template this file.
#./bootstrap/convert-config-to-template.sh


if [ -d data ]; then
    echo "Moving mutable directories to data/"
    # For now we need to most of the directories created by setup, including the "immutable" ones.
    # When we get full support for commons configuration we should revisit.
    for dir in db changelogDb config var import-tmp
    do
        echo "moving $dir to data/"
        # Use cp as it works across file systems.
        cp -r $dir data/$dir
        rm -fr $dir
    done
fi




