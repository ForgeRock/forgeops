#!/usr/bin/env bash
# Back up the directory now.

source /opt/opendj/env.sh

# Create a unique folder for this host's backup.
B="${BACKUP_DIRECTORY}/$HOSTNAME"

mkdir -p "$B"

echo "Doing a full online backup"
/opt/opendj/bin/backup --backupDirectory "${B}" \
  -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" \
  --compress \
  --trustAll \
  --backUpAll

# Now run the script to backup admin data.
/opt/opendj/scripts/backup-admin.sh



