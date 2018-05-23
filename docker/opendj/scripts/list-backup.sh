#!/usr/bin/env bash
# List backup. Defaults to today. Provide YYYY-MM-DD to view another day

source /opt/opendj/env.sh


NAMESPACE="${NAMESPACE:-default}"

if [ $# -eq 1 ]; 
then 
  DATESTAMP=$1
else
  DATESTAMP=`date "+%Y-%m-%d"`
fi

BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/bak}
# Create a unique folder for this host's backup.
B="${BACKUP_DIRECTORY}/${NAMESPACE}/${DJ_INSTANCE}/${DATESTAMP}"

if [ ! -d "${B}" ]; then
  echo "Can't find backup path $B"
  exit 1
fi

echo "Listing backups in $B"

echo "userRoot backups"

/opt/opendj/bin/restore --offline \
  --backupDirectory "${B}"/userRoot \
  --listBackups \
  --hostname "$FQDN" \
  -p 4444 -D "cn=Directory Manager"

echo "ctsRoot backups"

/opt/opendj/bin/restore --offline \
  --backupDirectory "${B}"/ctsRoot \
  --listBackups \
  --hostname "$FQDN" \
  -p 4444 -D "cn=Directory Manager"
