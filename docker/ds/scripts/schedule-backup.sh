#!/usr/bin/env bash
# Schedule directory cron tasks for full and incremental backup.
# See https://backstage.forgerock.com/knowledge/kb/article/a98768700

cd /opt/opendj

source /opt/opendj/env.sh

mkdir -p "$BACKUP_DIRECTORY"
chmod 775 "$BACKUP_DIRECTORY"

FULL_CRON="0 0 * * *"
INCREMENTAL_CRON="0 * * * *"

echo "Scheduling full backup at $FULL_CRON"
/opt/opendj/bin/backup --backupDirectory "${BACKUP_DIRECTORY}" \
  --hostname "${FQDN_DS0}" \
  -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" \
  --compress \
  --trustAll \
  --recurringTask "$FULL_CRON" \
  --backUpAll 

echo "Scheduling incremental backups at cron: $INCREMENTAL_CRON"
/opt/opendj/bin/backup --backupDirectory "${BACKUP_DIRECTORY}" \
  --hostname "${FQDN_DS0}" \
  -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" \
  --compress \
  --trustAll \
  --recurringTask "$INCREMENTAL_CRON" \
  --backUpAll  \
  --incremental

