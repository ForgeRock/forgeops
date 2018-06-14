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

set -x 

source /opt/opendj/env.sh

# Uncomment this to print experimental VM settings to stdout. -XshowSettings:vm
#java -version -XX:+UnlockDiagnosticVMOptions -XX:+PrintFlagsFinal

# If the pod was terminated abnormally the lock file may not have gotten cleaned up.

rm -f /opt/opendj/locks/server.lock
mkdir -p locks


restore() 
{
    echo "Attempting to restore from backup"
    if [ -z "$RESTORE_PATH" ]; then 
        scripts/restore.sh -o
    else
        scripts/restore.sh -o -p "$RESTORE_PATH"
    fi
}

# Check for a mounted secret volume. Fall back to secrets bundled in the image if we can't find them.
if [ ! -d "$SECRET_PATH" ]; then
    echo "Warning; Cannot find mounted secret volume on $SECRET_PATH. Falling back to using secrets bundled in the image"

    export DIR_MANAGER_PW_FILE=/opt/opendj/secrets/dirmanager.pw
    export MONITOR_PW_FILE=/opt/opendj/secrets/monitor.pw
    export KEYSTORE_FILE=/opt/opendj/secrets/keystore.pkcs12
    export KEYSTORE_PIN_FILE=/opt/opendj/secrets/keystore.pin
fi

relocate_data() 
{
    ls -lR data
    if [ -d data/db/userRoot/00000000.jdb ]; then 
        echo "Data volume contains existing data"
        return
    fi
    #     for dir in ads-truststore ctsRoot schema  tasks  userRoot 
    mkdir -p data/db
    for dir in ctsRoot userRoot ads-truststore admin
    do
        echo "Copying $dir"
        cp -r db/$dir data/db/$dir
    done
}

start() {
    echo "Starting OpenDJ"
    echo "Server id $SERVER_ID"
    # tood: fix 
    exec dumb-init -- ./bin/start-ds --nodetach
}

pause() {
    while true; do
        sleep 1000
    done
}

# Restore from a backup
restore() {
    if [ -d ./data/db ] ; then
        echo "It looks like there is existing directory data. Restore will not run."
        exit 0
    fi

    # run setup - because the directory needs to be configured
    # todo - See if we can restore a saved template instead.
    unset NUMBER_SAMPLE_USERS
    setup

    # We are currently using dsreplication initialize-all to load data from the first server 
    # So we restore data only on the first server and let initialization copy the data.
    if [[ $HOSTNAME = *"0"* ]]; then 
        echo "Restoring data from backup on host $HOSTNAME"
        scripts/restore.sh -o
    fi
}

CMD="${1:-run}"

echo "Command is $CMD"

echo "Server id is $SERVER_ID"

case "$CMD" in
start)
    # Start only. Will fail if there is no configuration
    relocate_data
    start
    ;;
restore-from-backup)
    restore
    ;;
restore-and-verify)
    # Restore from backup, and then verify the integrity of the data.
    scripts/restore.sh -o
    scripts/verify.sh
    ;;
backup)
    shift
    /opt/opendj/scripts/backup.sh "$@"
    ;;
setup-replication)
    # Runs post setup job that configures replication
    scripts/replicate-ds2ds.sh 
    ;;
pause) 
    pause
    ;;
debug)
    relocate_data
    bash
    ;;
*)
    exec "$@"
esac