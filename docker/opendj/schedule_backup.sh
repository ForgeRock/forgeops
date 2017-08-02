#!/usr/bin/env sh 
# Schedule automated backups.

cd /opt/opendj

BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/backup}

# If BACKUP_HOST is set, verify that we are the right host to run the backup.
if [ -n "$BACKUP_HOST" ];
then
    H=`hostname`
    if [ "$H" != "${BACKUP_HOST}" ];
    then
        echo "Our hostname is $H, and we are not the backup host: ${BACKUP_HOST}. Backups will not be scheduled on this host."
        exit 0
    fi
fi


if [ -n "$BACKUP_SCHEDULE_FULL" ];
then
    echo "Scheduling full backup with cron schedule ${BACKUP_SCHEDULE_FULL}"
    bin/backup --backupDirectory ${BACKUP_DIRECTORY}  -p 4444 -D "cn=Directory Manager" \
    -j ${DIR_MANAGER_PW_FILE} --trustAll --backupAll \
    --recurringTask "${BACKUP_SCHEDULE_FULL}"
fi

if [ -n "$BACKUP_SCHEDULE_INCREMENTAL" ];
then
    echo "Scheduling incremental backup with cron schedule ${BACKUP_SCHEDULE_FULL}"
    bin/backup --backupDirectory ${BACKUP_DIRECTORY}  -p 4444 -D "cn=Directory Manager" \
    -j ${DIR_MANAGER_PW_FILE} --trustAll  --backupAll \
    --recurringTask "${BACKUP_SCHEDULE_INCREMENTAL}"
fi
