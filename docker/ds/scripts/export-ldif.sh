#!/usr/bin/env bash
# Export backends via ldif 
# This can be initiated on any ds pod, but the export is performed on instance-0.

cd /opt/opendj 
source /opt/opendj/env.sh


echo "Exporting LDIF"

# TOOD: The calculation of roots only works within a single instance. 
# We can update this script to support remote ldif export by passing in the list of roots and target destination.
roots=`(cd db; echo *Root)`

mkdir -p "${BACKUP_DIRECTORY}"

for root in $roots; do
    t=`date "+%m%d%H%M%Y.%S"`

    F="${BACKUP_DIRECTORY}/${root}-${t}.ldif"
    echo "Exporting ldif of $root to $F"

    /opt/opendj/bin/export-ldif  --ldifFile "$F" \
      -p 4444 -D "cn=Directory Manager" -j "${DIR_MANAGER_PW_FILE}" --trustAll \
      --hostname "${FQDN_DS0}" \
      --compress \
      -n "${root}"
done


