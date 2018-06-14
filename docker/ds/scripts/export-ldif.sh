#!/usr/bin/env bash


source /opt/opendj/env.sh

# Create a unique folder for this host's backup.
B="${BACKUP_DIRECTORY}/$HOSTNAME/ldif"

mkdir -p "$B"


echo "Exporting LDIF"

for root in "userRoot" "ctsRoot"; do
    t=`date "+%m%d%H%M%Y.%S"`

    F="${B}/${root}-${t}.ldif"
    echo "Backing up $root to $F"

    /opt/opendj/bin/export-ldif  --ldifFile "$F" \
      -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" --trustAll \
      --compress \
      -n "${root}"
done


