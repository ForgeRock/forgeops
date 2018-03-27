#!/usr/bin/env bash
# This script is used to initialize or re-initialize replication.

ADMIN_ID="admin"

# First directory server in the set
DS0="${DJ_INSTANCE}-0.${DJ_INSTANCE}"


# Initialize replication of user data:
/opt/opendj/bin/dsreplication initialize-all  \
    --adminUID "$ADMIN_ID" \
    --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
    --port 4444 \
    --hostname "$DS0" \
    --baseDN "$BASE_DN" \
    --trustAll \
    --no-prompt


# Initialize replication of the CTS data:
/opt/opendj/bin/dsreplication initialize-all  \
    --adminUID "$ADMIN_ID" \
    --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
    --port 4444 \
    --hostname "$DS0" \
    --baseDN "o=cts" \
    --trustAll \
    --no-prompt
