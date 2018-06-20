#!/usr/bin/env bash
# Run the OpenDJ server
# We consolidate all of the writable DJ directories to /opt/opendj/data
# This allows us to to mount a data volume on that root which  gives us
# persistence across restarts of OpenDJ.
# For Docker - mount a data volume on /opt/opendj/data
# For Kubernetes mount a PV
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

cd /opt/opendj

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

# At runtime we set the Directory Manager password using the mounted secrets
update_ds_password()
{
    if [ ! -f "$DIR_MANAGER_PW_FILE" ]; then
        echo "Can't find the directory manager password file. Won't change the password"
        return
    fi
    echo "Updating the directory manager password"
    pw=`bin/encode-password  -s PBKDF2 -f $DIR_MANAGER_PW_FILE | sed -e 's/Encoded Password:  "//' -e 's/"//g'`
    pw="userPassword: $pw"
    head -n -2  db/rootUser/rootUser.ldif >/tmp/pw
    echo "$pw" >>/tmp/pw 
    mv /tmp/pw db/rootUser/rootUser.ldif
}

relocate_data() 
{
    if [ -d data/db/userRoot ]; then 
        echo "Data volume contains existing data"
        return
    fi
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
    relocate_data
    update_ds_password
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
pause) 
    pause
    ;;
debug)
    relocate_data
    update_ds_password
    bash
    ;;
*)
    exec "$@"
esac