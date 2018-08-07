#!/usr/bin/env bash
# List backups.

cd /opt/opendj

source /opt/opendj/env.sh


echo "Listing backups in ${BACKUP_DIRECTORY}"

roots=`(cd db; echo *Root)`

for root in $roots; do 
  echo "$root backups"
  /opt/opendj/bin/restore --offline \
    --backupDirectory "${BACKUP_DIRECTORY}"/$root \
    --listBackups \
    --hostname "$FQDN" \
    -p 4444 -D "cn=Directory Manager"
done