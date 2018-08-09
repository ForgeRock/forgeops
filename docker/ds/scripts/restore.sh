#!/usr/bin/env bash
# This will do an online restore of a previous backup. 


cd /opt/opendj

source env.sh 

usage()
{ 
    echo "$0 [-o] [-p path] [-n]"
    echo "-o  do an offline restore. DS must not be running."
    echo "-p path. Restore files starting at this path. If this option is not provided, the most recent backup at $BACKUP_DIRECTORY is restored"
    echo "-n  dry-run option. Show what would be restored"
    exit 1
}

RESTORE_PATH="$BACKUP_DIRECTORY"

while getopts ":p:on" opt; do
    case $opt in 
        o)  OFFLINE=true ;;
        p)  RESTORE_PATH="$OPTARG" ;;
        n)  DRY_RUN="--dry-run" ;;
        \?) usage ;;
    esac
done

if [ !  -z "${OFFLINE}" ]; then
    ARGS="--offline"
else
    ARGS="--hostname ${FQDN_DS0} --port 4444 --bindDN \"cn=Directory\\ Manager\" -j ${DIR_MANAGER_PW_FILE} --trustAll"
fi

fail() 
{
  echo "Error : restore path is not valid. Current path $RESTORE_PATH"
  exit 1
}

ERR=0

restore() 
{
    echo "Restoring from backup at $RESTORE_PATH"
    cd $RESTORE_PATH || fail 
    for dir in `ls` 
    do
        d="${RESTORE_PATH}/${dir}"
        echo /opt/opendj/bin/restore $ARGS --backupDirectory "$d" $DRY_RUN
        eval /opt/opendj/bin/restore $ARGS --backupDirectory "$d" $DRY_RUN
        if [ "$?" -ne 0 ]; then
            ERR="$?"
            echo "warning: restore had a non zero exit $ERR"
        fi
    done
}

restore

exit $ERR
