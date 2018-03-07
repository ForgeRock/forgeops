#!/usr/bin/env bash
# Back up the directory now.

source /opt/opendj/env.sh

# Create a unique folder for this host's backup.
B="${BACKUP_DIRECTORY}/$HOSTNAME"

mkdir -p "$B"

echo "Doing a full backup"
/opt/opendj/bin/backup --backupDirectory "${B}" \
  -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" \
  --compress \
  --trustAll \
  --backUpAll

echo "Backing up additional configuration files under /opt/opendj/data"

cd /opt/opendj/data

t=`date "+%m%d%H%M%Y.%S"`
tar cvfz "${B}/admin-bak-${t}.tar.gz" config var db/admin db/ads-truststore db/*ldif db/rootUser


