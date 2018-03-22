#!/usr/bin/env bash


source /opt/opendj/env.sh

B="${BACKUP_DIRECTORY}/$HOSTNAME"

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
