#!/usr/bin/env sh 
# Schedule automated backups.

set -x

echo "Scheduling backup"


# The first node in the cluster is where we run backups.
host="${DJ_INSTANCE}-0.${DJ_INSTANCE}"
# Create a unique folder for this hosts backup.
B="${BACKUP_DIRECTORY}/${host}"

mkdir -p "$B"

if [ -n "$BACKUP_SCHEDULE_FULL" ];
then
    echo "Scheduling full backup with cron schedule ${BACKUP_SCHEDULE_FULL}"
    bin/backup --backupDirectory ${B} \
    -p 4444 -D "cn=Directory Manager" \
    --hostname "${host}" \
    -j ${DIR_MANAGER_PW_FILE} --trustAll --backupAll \
    --recurringTask "${BACKUP_SCHEDULE_FULL}"
fi

if [ -n "$BACKUP_SCHEDULE_INCREMENTAL" ];
then
    echo "Scheduling incremental backup with cron schedule ${BACKUP_SCHEDULE_FULL}"
    bin/backup --backupDirectory ${B}  -p 4444 -D "cn=Directory Manager" \
    -j ${DIR_MANAGER_PW_FILE} --trustAll  --backupAll \
    --hostname "${host}" \
    --incremental \
    --recurringTask "${BACKUP_SCHEDULE_INCREMENTAL}"
fi
