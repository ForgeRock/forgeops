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

# Given a file $1 containing a new password, and an ldif file $2
# Replace the userPassword attribute with the new password
update_pw() {
     if [ ! -f "$1" ]; then
        echo "Can't find the password file $1. Won't change the password in $2"
        return
    fi

    echo "Updating the password in $2"
    # Set the JVM args so we dont blow up the container memory.
    pw=$(OPENDJ_JAVA_ARGS="-Xmx256m" bin/encode-password  -s PBKDF2 -f $1 | sed -e 's/Encoded Password:  "//' -e 's/"//g' 2>/dev/null)
    # $pw can contian / - so need to use alternate sed delimiter.
    sed -ibak "s#userPassword: .*#userPassword: $pw#" "$2"
}

relocate_data() 
{
    # Does data/db contain directories?
    if [ "$(find data/db  -type d)" ]; then
        echo "Data volume contains existing data"
	# If continer is restarted then original db directory reappears 
	# from the docker image hence move it out of the way otherwise
	# symbolic linking below will not work
	mv db db.tmp || true
	ln -s data/db .
    else
        # The data directory is mounted as pvc in k8s env.  If testing
        # with "docker run",  make sure to  mount a data volume

        # If there is no "db" under "data" then this must be the first time
        echo "No existing data found. Moving default db directory to data partition and symbolic linking it"
        mv db/ data/
        ln -s data/db .
    fi
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
    # Set the passwords to the values of the mounted secrets.
    update_pw "$DIR_MANAGER_PW_FILE" data/db/rootUser/rootUser.ldif
    update_pw "$MONITOR_PW_FILE"  data/db/monitorUser/monitorUser.ldif
}

# Restore from a backup
restore() {
    if [ "$(find data/db  -type d)" ]; then
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
