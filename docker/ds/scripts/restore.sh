#!/usr/bin/env bash
# This will do an online restore of a previous backup. 
# The backup folder structure is organized by date: bak/year/month/day/.

usage()
{ 
    echo "$0 [-o] [-p path] [-n]"
    echo "-o  do an offline restore. DS must not be running."
    echo "-p path. Restore files starting at the path. If this option is not provided, the most recent backup is restored"
    echo "-n  dry-run option. Show what would be restored"
    exit 1
}

cd /opt/opendj

source env.sh 

# The default root of the backup folder includes the namespace and instance name. 
# This disambiguates backups running on the same cluster.
BACKUP_DIRECTORY="/opt/opendj/bak/"

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
    echo "Restore path is $RESTORE_PATH"
    cd $RESTORE_PATH || fail 
    for dir in `ls` 
    do
        d="${RESTORE_PATH}/${dir}"
        if [ "$dir" = "userRoot" ] || [ "$dir" = "ctsRoot" ]; 
        then 
           echo /opt/opendj/bin/restore $ARGS --backupDirectory "$d" 
            eval /opt/opendj/bin/restore $ARGS --backupDirectory "$d" $DRY_RUN
             if [ "$?" -ne 0 ]; then
                ERR="$?"
                echo "warning: restore had a non zero exit $ERR"
            fi
        fi
    done
    cd /opt/opendj
}

# Recurses from the root of the instance backup folder to find the latest backup.
# This assumes the directory folders is organized by year/month/day/
find_latest() 
{
   cd ${BACKUP_DIRECTORY} || fail
   year=`ls . | sort -r | head -1`
   cd $year || fail
   month=`ls -t | sort -r | head -1` 
   cd $month || fail
   day=`ls -t  | sort -r | head -1`
   cd $day || fail
   RESTORE_PATH=`pwd`
   if [ ! -d "${RESTORE_PATH}" ]; then 
	fail
   fi 
   cd /opt/opendj
}

# If no restore path is specified, find the lastest backup.
# This sets RESTORE_PATH as a side effect.
if [ -z "${RESTORE_PATH}" ]; then 
    find_latest
fi

restore "$RESTORE_PATH"

exit $ERR
