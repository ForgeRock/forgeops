#!/usr/bin/env bash
# restore data
# This is done offline, and is expected to be run by a job that runs to termination.
# The first argument ($1) is the directory to search for the files to restore
# All files found at the directory will be restored. If you only want to partially restore files
# you must modify this script or delete the files from the restore source.

set -e


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


# Make sure the DS version matches any backend JE data
echo "Upgrading configuration and data..."
./upgrade --dataOnly --acceptLicense --force --ignoreErrors --no-prompt


echo "Restoring files found in $SOURCE:"
ls -lR $SOURCE

if [[ $BACKUP_TYPE == "ldif" ]]; then
     # Strip the .ldif from the filename to get the name of the backend
    BACKEND=$(cd $SOURCE; ls | sed -e s/\.ldif//g )

    for B in $BACKEND
    do
        # Import the data.
        F="${SOURCE}/$B.ldif"
        echo "Importing $F to $B"
        import-ldif -F --ldifFile  "$F" --backendId $B --offline
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