#!/usr/bin/env bash
# Back up the directory now.
# See https://backstage.forgerock.com/knowledge/kb/article/a98768700

cd /opt/opendj

source /opt/opendj/env.sh

#DATESTAMP=`date "+%Y/%m/%d"`

mkdir -p "${BACKUP_DIRECTORY}"
chmod 775 "${BACKUP_DIRECTORY}"

IDS=()

if [ "${DS_ENABLE_USERSTORE}" = "true" ]; then
	IDS+=(" --backendId amIdentityStore")
fi
if [ "${DS_ENABLE_IDMREPO}" = "true" ]; then
	IDS+=(" --backendId idmRepo")
fi
if [ "${DS_ENABLE_CONFIGSTORE}" = "true" ]; then
	IDS+=(" --backendId cfgStore")
fi
if [ "${DS_ENABLE_CTS}" = "true" ]; then
	IDS+=(" --backendId amCts")
fi

if [ ${#IDS[@]} -eq 0 ]; then
	echo "Nothing to backup. Are any env var DS_ENABLE_* set?"
	exit 0
fi

# If no full backup exists, the --incremental option will create one.
echo "Starting backup to ${BACKUP_DIRECTORY}"
OPENDJ_JAVA_ARGS="-Xmx512m" /opt/opendj/bin/backup --hostname localhost --port 4444 \
    --bindDn "cn=Directory Manager" --bindPasswordFile "${DIR_MANAGER_PW_FILE}" \
    --backupDirectory "${BACKUP_DIRECTORY}" \
    --compress \
    --trustAll \
    --incremental \
    ${IDS[@]}