#!/usr/bin/env bash
# Initialize from a backup. We assume the files to restore are in the bak/ folder
# This runs in an init container. DS is not running.
# This is a prototype - do not use in production.

cd /opt/opendj

set -x

if [ "$OVERWRITE_DATA" = "true" ]
then
    rm -fr data/*
fi

if [ -d data/db/schema ]; then
    echo "It looks like there is existing data in the data/db directory. Restore will not overwrite exiting data."
    exit 0
fi

# When we restore, we want to take the backup from the first node in set (instance-0).
B="${BACKUP_DIRECTORY}/${DJ_INSTANCE}-0"

# Admin files to restore first...
admin="${B}/admin"


LATEST_TAR=`ls -t "$admin" | head -1`

if [ -z "$LATEST_TAR" ]; then
    echo "No backup files to restore. Exiting"
    exit 0
fi

echo "Restoring admin tar : $LATEST_TAR"


# In case the path does not exist.
mkdir -p data/db

(cd data; tar xvfz "$admin/$LATEST_TAR")


# This is tricky, and we should find a more robust way to get the last backup.
# First find the most recent backup file in userRoot.
LAST_BACKUP=`ls -t "${B}/userRoot/backup-"* | head -1`
# The last 15 characters of the filename are the backup id.
BACKUP_ID=${LAST_BACKUP: -15}

# We need to restore the top level sym links as well.
for d in data/*
do
    ln -s $d
done

echo "restoring DS backup id $BACKUP_ID"

for db in "ctsRoot" "schema" "tasks" "userRoot"; do
    d="${B}/$db"
    echo "restoring $d"
    bin/restore --offline --backupDirectory "$d" --backupID ${BACKUP_ID}
done


# If this restored to a different node, this sets the server id so we don't clash with other nodes.
# TODO: Use commons to parameterize the server id
echo "Set the global server id to $SERVER_ID"
bin/dsconfig  set-global-configuration-prop --set server-id:$SERVER_ID  --offline  --no-prompt

echo "done"
