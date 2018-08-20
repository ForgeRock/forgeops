#!/usr/bin/env bash
# Back up the directory now.
# See https://backstage.forgerock.com/knowledge/kb/article/a98768700

cd /opt/opendj

source /opt/opendj/env.sh

#DATESTAMP=`date "+%Y/%m/%d"`

mkdir -p "$BACKUP_DIRECTORY"
chmod 775 "$BACKUP_DIRECTORY"

# If no full backup exists, the --incremental option will create one.
echo "Starting backup to ${BACKUP_DIRECTORY}"
/opt/opendj/bin/backup --backupDirectory "${BACKUP_DIRECTORY}" \
  --hostname localhost \
  -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" \
  --compress \
  --trustAll \
  --backUpAll \
  --incremental



