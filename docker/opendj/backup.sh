#!/usr/bin/env sh 
# Back up the directory now.

BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/backup}

# Create a unique folder for this hosts backup
B="${BACKUP_DIRECTORY}/$HOSTNAME"

mkdir -p "$B"

/opt/opendj/bin/backup --backupDirectory "${B}" \
  -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" \
   --trustAll \
  --backUpAll
