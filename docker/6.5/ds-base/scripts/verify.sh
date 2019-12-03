#!/usr/bin/env bash
# Verify the backed up data.

cd /opt/opendj

source env.sh

for instance in ${BACKUP_DIRECTORY}/*; do

	echo "Verifying instance $instance"

    bin/restore --dry-run --backupDirectory $instance \
        --hostname "${FQDN_DS0}" \
        -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" \
        --trustAll
done
