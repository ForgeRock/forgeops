#!/usr/bin/env bash
# List backups.

cd /opt/opendj

source /opt/opendj/env.sh

echo "Listing backups in ${BACKUP_DIRECTORY}"

cd "${BACKUP_DIRECTORY}"

for root in *; do 
  echo "$root backups"
  /opt/opendj/bin/restore  --offline \
    --backupDirectory "${BACKUP_DIRECTORY}/${root}" \
    --listBackups 
done