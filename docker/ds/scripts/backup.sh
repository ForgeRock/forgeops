#!/usr/bin/env bash
# Back up the directory now. Additional command line arguments are passed to the backup command.
# See https://backstage.forgerock.com/knowledge/kb/article/a98768700

cd /opt/opendj

source /opt/opendj/env.sh

NAMESPACE="${NAMESPACE:-default}"

DATESTAMP=`date "+%Y/%m/%d"`

BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/bak}
# Create a unique folder for this host's backup.
B="${BACKUP_DIRECTORY}/${NAMESPACE}/${DJ_INSTANCE}/${DATESTAMP}"

# Note: the mkdir runs locally, not on the remote server. We can however mount the bak/ nfs folder...
# The backup command creates the path for us, so this is not required, but left here for documentation purposes:
#mkdir -p "$B"

echo "Starting backup to ${B}"
/opt/opendj/bin/backup --backupDirectory "${B}" \
  --hostname "${FQDN_DS0}" \
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

# TODO:  These commands need to execute on one of the ds/rs nodes in the cluster. Not on a temporary node.
echo "Backing up additional files to $B"
for file in data/db/admin data/db/ads-truststore; do
  cp -r "$file" "$B"
done

