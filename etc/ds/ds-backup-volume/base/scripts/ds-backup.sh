#!/usr/bin/env bash
# Export backend data using ldif or ds-backup
# This is done offline, and is expected to be run by a job that runs to termination

set -e

# Target to export data to
BACKUP_DIR=${BACKUP_DIR:-/backup}

# The backup type defaults to ldif. Use ds-backup for a directory backup command
BACKUP_TYPE=${BACKUP_TYPE:-ldif}

DEST="$BACKUP_DIR/$NAMESPACE/$BACKUP_TYPE"
mkdir -p  $DEST


# The DS server version needs to match the JE data version
echo "Upgrading configuration and data..."
./upgrade --dataOnly --acceptLicense --force --ignoreErrors --no-prompt


# Calculate the list of backends.
mapfile -t BACK_ENDS < <(./bin/ldifsearch -b cn=backends,cn=config -s one config/config.ldif "(&(objectclass=ds-cfg-pluggable-backend)(ds-cfg-enabled=true))" ds-cfg-backend-id | grep "^ds-cfg-backend-id" | cut -c20-)

echo "Backends ${BACK_ENDS[@]}"

for B in "${BACK_ENDS[@]}"; do

    if [[ "$B" =~ ^(rootUser|proxyUser|monitorUser|tasks|adminRoot)$ ]]; then
        echo "Skipping system backend $B"
    else
        if [[ $BACKUP_TYPE == "ldif" ]];
        then
            F="$DEST/$B.ldif"
            echo "Backing up $B to $F"
            export-ldif --ldifFile $F --backendId $B --offline
        else
            echo  "Backing up $B to $DEST"
            dsbackup --offline create --backupLocation "$DEST" --backendName $B
        fi
    fi
done
