#!/usr/bin/env bash
# This backs up everything *except* user data.
# Revisit when https://bugster.forgerock.org/jira/browse/OPENDJ-4852 is fixed.


source /opt/opendj/env.sh


cd /opt/opendj/data

# Create a unique folder for this host's backup.
B="${BACKUP_DIRECTORY}/$HOSTNAME/admin"

mkdir -p "$B"

t=`date "+%m%d%H%M%Y.%S"`

# Backup all the files that the binary backup command does NOT include.
tar cvfz "${B}/admin-${t}.tar.gz" \
    --exclude './db/*Root' .