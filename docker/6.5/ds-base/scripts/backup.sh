#!/usr/bin/env bash
# Back up the directory now.
# See https://backstage.forgerock.com/knowledge/kb/article/a98768700

cd /opt/opendj

source /opt/opendj/env.sh

BACKUP_DIRECTORY="${BACKUP_DIRECTORY:-/opt/opendj/bak}"

mkdir -p "${BACKUP_DIRECTORY}"
chmod -f 775 "${BACKUP_DIRECTORY}"


# If no full backup exists, the --incremental option will create one.
echo "Starting backup to ${BACKUP_DIRECTORY}"
OPENDJ_JAVA_ARGS="-Xmx512m" /opt/opendj/bin/backup --hostname localhost --port 4444 \
    --bindDn "cn=Directory Manager" --bindPasswordFile "${DIR_MANAGER_PW_FILE}" \
    --backupDirectory "${BACKUP_DIRECTORY}" \
    --compress \
    --trustAll \
    --incremental \
    --backupAll