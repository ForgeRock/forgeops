#!/usr/bin/env bash
# Back up the directory now. Additional command line arguments are passed to the backup command.

cd /opt/opendj

source /opt/opendj/env.sh

# Create a unique folder for this host's backup.
B="${BACKUP_DIRECTORY}/$HOSTNAME"

mkdir -p "$B"

echo "Starting backup"
/opt/opendj/bin/backup --backupDirectory "${B}" \
  -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" \
  --compress \
  --trustAll \
  --backUpAll $*

if [ $? -eq 0 ]
then
    scripts/notify.sh "Online backup to $B completed OK" "INFO"
else
   scripts/notify.sh "Online backup to $B failed" "ERROR"
fi

# Now run the script to backup admin data.
/opt/opendj/scripts/backup-admin.sh

