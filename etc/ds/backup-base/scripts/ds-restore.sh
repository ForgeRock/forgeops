#!/usr/bin/env bash
# restore data
# This is done offline, and is expected to be run by a job that runs to termination.
# The first argument ($1) is the directory to search for the files to restore
# All files found at the directory will be restored. If you only want to partially restore files
# you must modify this script or delete the files from the restore source.

set -x

if [[ "$#" -lt 1 ]]; then
    echo "usage: $0 restore-files-dir"
    exit 1
fi

# Backup type is ldif or ds-backup
BACKUP_TYPE="${BACKUP_TYPE:-ldif}"
SOURCE="$1/$NAMESPACE/$BACKUP_TYPE"

[ -d "$SOURCE" ] || {
    echo "Directory $SOURCE DOES NOT exist."
    exit 1
}

# Call the entrypoint - to make sure the proto backends are restored
/opt/opendj/docker-entrypoint.sh initialize-only

echo "Restoring files found in $SOURCE:"
ls -lR $SOURCE


if [[ $BACKUP_TYPE == "ldif" ]]; then
    LDIF=$(cd $SOURCE; ls *.ldif*)
    for F in $LDIF
    do
        # Strip the .ldif or .ldif.gz from the filename to get backend name
        BACKEND=$(echo $F | sed -e s/\.ldif\.*//g) 
        if [[ $F =~ ".gz" ]]; then
            echo "=> Importing compressed $F to $BACKEND"
            import-ldif --clearBackend --ldifFile "${SOURCE}/$F" --backendId ${BACKEND} --offline --isCompressed
        else
            echo "=> Importing $F to $BACKEND"
            import-ldif --clearBackend --ldifFile "${SOURCE}/$F" --backendId ${BACKEND} --offline
        fi
    done
else
    # use ds-restore command

    # For debugging:
    # dsbackup --offline list --backupLocation $SOURCE

    # Get a list of all the last backups
    BACKENDS=$(dsbackup --offline list  --backupLocation $SOURCE --last | grep "Backup ID" | awk '{print $NF}' )

    for B in $BACKENDS
    do
        echo "Restoring id $B"
        echo dsbackup --offline  restore  --backupLocation $SOURCE --backupId $B
        dsbackup --offline  restore  --backupLocation $SOURCE --backupId $B
    done

fi