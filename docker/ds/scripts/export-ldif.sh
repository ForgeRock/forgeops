#!/usr/bin/env bash
# Export backends via ldif 
# This can be initiated on any ds pod, but the export is performed on instance-0.

source /opt/opendj/env.sh

# The parent path must exist on the remote host.
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/bak}


echo "Exporting LDIF"

for root in "userRoot" "ctsRoot"; do
    t=`date "+%m%d%H%M%Y.%S"`

    F="${BACKUP_DIRECTORY}/${root}-${t}.ldif"
    echo "Backing up $root to $F"

    /opt/opendj/bin/export-ldif  --ldifFile "$F" \
      -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" --trustAll \
      --hostname "${FQDN_DS0}" \
      --compress \
      -n "${root}"
done


