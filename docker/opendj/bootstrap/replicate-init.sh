#!/usr/bin/env bash
# This script is used to initialize or re-initialize replication.

# TODO: use post-external-initialise when reinitializing from a restore

ADMIN_ID="admin"

# Need to set this so that pod does not run out of resources and hence OOM
OPENDJ_JAVA_ARGS="-server -Xms2g -Xmx2g -XX:+UseCompressedOops -XX:+UseG1GC -XX:MaxGCPauseMillis=100"

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
