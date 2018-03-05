#!/usr/bin/env sh
# Run the OpenDJ server
# We consolidate all of the writable DJ directories to /opt/opendj/data
# This allows us to to mount a data volume on that root which  gives us
# persistence across restarts of OpenDJ.
# For Docker - mount a data volume on /opt/opendj/data
# For Kubernetes mount a PV
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

cd /opt/opendj

# If the pod was terminated abnormally the lock file may not have gotten cleaned up.
rm -f /opt/opendj/locks/server.lock

# Uncomment this to print experimental VM settings to the stdout.
java -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAMFraction=1 -XshowSettings:vm -version

source /opt/opendj/env.sh

configure() {
      # Instance dir does not exist? Then we need to run setup
    if [ ! -d ./data/config ] ; then
      echo "Instance data Directory is empty. Creating new DJ instance"
       echo "Running $BOOTSTRAP"
       sh "${BOOTSTRAP}"
    fi
}

start() {
    if [ -d "${SECRET_PATH}" ]; then
      echo "Secret path is present. Will copy any keystores and truststore"
      # We send errors to /dev/null in case no data exists.
      cp -f ${SECRET_PATH}/key*   ${SECRET_PATH}/trust* ./data/config 2>/dev/null
    fi

    # todo: Check /opt/opendj/data/config/buildinfo
    # Run upgrade if the server is older

    if (bin/status -n | grep Started) ; then
       # If we have just been configured, a restart is needed to ensure we pick up any JVM env var args
       echo "Restarting OpenDJ after installation."
       bin/stop-ds
    fi

    echo "Starting OpenDJ"

    # Remove any bootstrap sentinel created by setup.
    rm -f /opt/opendj/BOOTSTRAPPING

    # instance.loc points DJ at the data/ volume
    echo $INSTANCE_ROOT >/opt/opendj/instance.loc
    exec ./bin/start-ds --nodetach
}

CMD="${1:-run}"

echo "Command is $CMD"


case "$CMD" in
run)
    # Configure (if configuration does not already exist), and then start
    # This is the default action.
    configure
    start
    ;;
configure)
    # Configure only
    configure
    ;;
start)
    # Start only. Will fail if there is no configuration
    start
    ;;
*)
    exec "$@"
esac