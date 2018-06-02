#!/usr/bin/env bash
# This script is used to initialize or re-initialize replication.

ADMIN_ID="admin"

# Need to set this so that pod does not run out of resources and hence OOM
OPENDJ_JAVA_ARGS="-server -Xms2g -Xmx2g -XX:+UseCompressedOops -XX:+UseG1GC -XX:MaxGCPauseMillis=100"

# First directory server in the set
DS0="${DJ_INSTANCE}-0.${DJ_INSTANCE}"

# Initiaize all -used on a fresh cluster with no data.
initall() {
    # Initialize replication of user data:
    /opt/opendj/bin/dsreplication initialize-all  \
        --adminUID "$ADMIN_ID" \
        --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
        --port 4444 \
        --hostname "$DS0" \
        --baseDN "$1" \
        --trustAll \
        --no-prompt

}


# This is used when all instances are being intialized/restored from the same backup
initPostRestore() {
    echo "configuring post-external-initialization on $1"

    # Initialize replication of the CTS data:
    /opt/opendj/bin/dsreplication post-external-initialization  \
        --adminUID "$ADMIN_ID" \
        --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
        --port 4444 \
        --hostname "$DS0" \
          -b "$1" \
        --trustAll \
        --no-prompt
}


# todo: We want more flexibility here in how replication is initialized. Revist
initall $BASE_DN 
initall "o=cts"

#initPostRestore "$BASE_DN"
#initPostRestore "o=cts"
