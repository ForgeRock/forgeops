#!/usr/bin/env bash
# This will do an online restore of a previous backup.

BACKUP_ID=$1
if [ -z "$BACKUP_ID" ]; then
    echo "Usage: restore.sh BACKUP_ID"
    exit 1
fi

source /opt/opendj/env.sh

B="${BACKUP_DIRECTORY}/$HOSTNAME"

/opt/opendj/bin/restore \
 --hostname "$FQDN" \
 --port 4444 \
 --bindDN "cn=Directory Manager" \
  -j "${DIR_MANAGER_PW_FILE}" \
 --trustAll \
  --backupDirectory "${B}"/userRoot \
 --backupID ${BACKUP_ID} \
 --start 0 \
 --trustAll

