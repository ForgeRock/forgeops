#!/usr/bin/env bash
# This script is used to initialize or re-initialize replication.

set -x

source /opt/opendj/env.sh

# First directory server in the set
DS0="${DJ_INSTANCE}-0.${DJ_INSTANCE}"


# Initialize replication data:
/opt/opendj/bin/dsreplication initialize-all  \
    --adminUID "$ADMIN_ID" \
    --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
    --port 4444 \
    --hostname "$DS0" \
    --baseDN "$BASE_DN" \
    --trustAll \
    --no-prompt


