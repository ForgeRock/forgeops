#!/usr/bin/env bash
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
mkdir -p locks


# If the Directory Manager password file is mounted, grab the password from that, otherwise default.
# See https://github.com/kubernetes/kubernetes/issues/40651
# https://github.com/kubernetes/kubernetes/issues/30427
if [ ! -r "$DIR_MANAGER_PW_FILE" ]; then
    echo "Warning; Cannot find path to $DIR_MANAGER_PW_FILE. I will create a default password"
    mkdir -p "$SECRET_PATH"
    echo -n "password" > "$DIR_MANAGER_PW_FILE"
fi


# Create a default monitor user password if one does not exist.
# https://github.com/kubernetes/kubernetes/issues/30427
if [ ! -r "$MONITOR_PW_FILE" ]; then
    echo "Warning; Cannot find path to $MONITOR_PW_FILE. I will create a default password"
    mkdir -p "$SECRET_PATH"
    echo -n "password" > "$MONITOR_PW_FILE"
fi


# Uncomment this to print experimental VM settings to stdout.
#java -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAMFraction=1 -XshowSettings:vm -version

source /opt/opendj/env.sh

setup() {
      # If the instance data does not exist we need to run setup.
    if [ ! -d ./data/db ] ; then
      echo "Instance data Directory is empty. Creating new DJ instance"
      BOOTSTRAP="${BOOTSTRAP:-/opt/opendj/bootstrap/setup.sh}"
      # DS setup complains if the directory is not empty.
      echo "Running $BOOTSTRAP"
      "${BOOTSTRAP}"
    else
        echo "Instance directory ./data/db is not empty. Setup will be skipped"
    fi
}

start() {

    # todo: Check /opt/opendj/data/config/buildinfo
    # Run upgrade if the server is older

    echo "Starting OpenDJ"

    # Remove any bootstrap sentinel created by setup.
    rm -f /opt/opendj/BOOTSTRAPPING

    # If there is a ./data directory present, create sym links for any top level directories.
    # todo: When commons configuration lands, we should modify config.ldif to point to the directory locations.
    if [ -d data/db ]; then
        for d in data/*
        do
            ln -s $d
        done
    fi

    if [ -d "${SECRET_PATH}" ]; then
      echo "Secret path is present. Will copy any keystores and truststore"
      # We send errors to /dev/null in case no data exists.
      cp -f ${SECRET_PATH}/key*   ${SECRET_PATH}/trust* ./config 2>/dev/null
    fi

    echo "Server id $SERVER_ID"

    exec ./bin/start-ds --nodetach
}

CMD="${1:-run}"

echo "Command is $CMD"


case "$CMD" in
run)
    # Setup (if configuration does not already exist), and then start.
    # This is the default action.
    setup
    start
    ;;
setup)
    # Configure/setup only.
    setup
    ;;
start)
    # Start only. Will fail if there is no configuration
    start
    ;;
run-post-setup-job)
    # Runs post setup job that configures replication
    /opt/opendj/bootstrap/post-setup-job.sh
    ;;
restore-from-backup)
    # Re-initializes DS from a previous backup. Use this instead of setup.
    /opt/opendj/bootstrap/restore-from-backup.sh
    ;;
*)
    exec "$@"
esac