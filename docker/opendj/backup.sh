#!/usr/bin/env sh 
# Back up the directory now.
cd /opt/opendj

BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/opt/opendj/backup}
DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE:-/var/secrets/opendj/dirmanager.pw}

bin/backup --backupDirectory ${BACKUP_DIRECTORY}  \
  -p 4444 -D "cn=Directory Manager" -j ${DIR_MANAGER_PW_FILE} --trustAll \
  --backUpAll
