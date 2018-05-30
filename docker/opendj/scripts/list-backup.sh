#!/usr/bin/env bash
# List backups.

source /opt/opendj/env.sh

if [ $# -eq 1 ]; 
then 
  B=$1
else
  echo "Usage: $0 path-to-backup-files"
  echo "Example: $0 bak/user/namespace/2018/06/01"
  exit 1
fi

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
