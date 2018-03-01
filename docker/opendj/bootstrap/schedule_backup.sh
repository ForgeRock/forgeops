#!/usr/bin/env sh 
# Schedule automated backups.


echo "Scheduling backup"

BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/backup}


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
    --incremental \
    --recurringTask "${BACKUP_SCHEDULE_INCREMENTAL}"
fi
