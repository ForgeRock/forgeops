#!/usr/bin/env bash
# Run the DS server
# We consolidate all of the writable DS directories to /opt/opendj/data
# This allows us to to mount a data volume on that root which  gives us
# persistence across DS restarts.
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


# At runtime we set the Directory Manager password using the mounted secrets
update_ds_password()
{
    if [ ! -f "$DIR_MANAGER_PW_FILE" ]; then
        echo "Can't find the directory manager password file. Won't change the password"
        return
    fi
    echo "Updating the directory manager password"
    pw=`bin/encode-password  -s PBKDF2 -f $DIR_MANAGER_PW_FILE | sed -e 's/Encoded Password:  "//' -e 's/"//g' 2>/dev/null`
    pw="userPassword: $pw"
    head -n -2  db/rootUser/rootUser.ldif >/tmp/pw
    echo "$pw" >>/tmp/pw 
    mv /tmp/pw db/rootUser/rootUser.ldif

    if [ ! -f "$MONITOR_PW_FILE" ]; then
        echo "Can't find the monitor user password file. Won't change the password"
        return
    fi

    echo "Updating the monitor user password"
    pw=`bin/encode-password  -s PBKDF2 -f $MONITOR_PW_FILE | sed -e 's/Encoded Password:  "//' -e 's/"//g' 2>/dev/null`
    pw="userPassword: $pw"
    head -n -2  db/monitorUser/monitorUser.ldif >/tmp/pw
    echo "$pw" >>/tmp/pw 
    mv /tmp/pw db/monitorUser/monitorUser.ldif
}

relocate_data() 
{
    if [ -d data/db/userRoot ]; then 
        echo "Data volume contains existing data"
        return
    fi
    mkdir -p data/db
    for dir in ctsRoot userRoot ads-truststore adminRoot idmRoot
    do
        echo "Copying $dir"
        cp -r db/$dir data/db/$dir
    done
}

start() {
    echo "Starting DS"
    echo "Server id $SERVER_ID"
    #exec dumb-init -- ./bin/start-ds --nodetach
    exec tini -v -- ./bin/start-ds --nodetach
}

pause() {
    while true; do
        sleep 1000
    done
}


init_container() {
    relocate_data
    update_ds_password
}


# Restore from a backup
restore() {
    if [ -d data/db/userRoot ]; then 
        echo "Restore will not overwrite existing data."
        exit 0
    fi

    init_container

    echo "Restoring data from backup on host $HOSTNAME"
    scripts/restore.sh -o
}


CMD="${1:-run}"

echo "Command is $CMD"

echo "Server id is $SERVER_ID"


case "$CMD" in
start)
    init_container
    start
    ;;
restore)
    restore
    ;;
verify)
    scripts/verify.sh
    ;;
pause)
    pause
    ;;
*)
    exec "$@"
esac