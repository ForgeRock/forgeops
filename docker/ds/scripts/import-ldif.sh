#!/usr/bin/env bash
# import ldif
# This can be initiated on any ds pod, but the import is performed on instance-0.
# Supply the path to the ldif file to import and the backend name (amIdentityStore, amCts, etc.)

source /opt/opendj/env.sh

# The parent path must exist on the remote host.
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/bak}

FILE="$1"
BACKEND="$2"

if [ -z "$FILE" ] || [ -z "$BACKEND" ] ; then 
  echo "Usage: $0 file.ldif backendName"
fi

echo "Importing LDIF from $FILE for backend $BACKEND"

# --clearBackend
/opt/opendj/bin/import-ldif --ldifFile "$FILE" \
  -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" --trustAll \
  --hostname "${FQDN_DS0}" \
  --isCompressed \
  --clearBackend \
  -n "${BACKEND}"



