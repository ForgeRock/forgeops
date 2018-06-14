#!/usr/bin/env bash
# Configure and Initialize replication for the cluster - assumes that the
# directory servers are also replication servers.
#
# Copyright (c) 2017-2018 ForgeRock AS. All rights reserved.
#

cd /opt/opendj 

source env.sh

#quick_setup

# Reset JVM so that pod does not run out of resources and hence OOM
export OPENDJ_JAVA_ARGS="-server -Xmx1g"

ADMIN_ID=admin

# Put an echo in front of this command if you just want to see what the script does.
dsreplica="/opt/opendj/bin/dsreplication"

if [ -z "$DS_SET_SIZE" ]; then
    echo "DS_SET_SIZE is not set!. We need to know how many DS nodes are in the statefulSet"
    exit 1
fi

# Search for an LDAP host. Return 0 if it is available.
search() {
    echo "Waiting for server $1 to be available"
    /opt/opendj/bin/ldapsearch -h "$1" -j "$DIR_MANAGER_PW_FILE" -p 1389 -D "cn=Directory Manager" \
     --baseDN "$BASE_DN" -s base -l 5 \
     "(objectClass=*)" 1.1
}

# index of last server in the set.
let last_ds="$DS_SET_SIZE - 1"

# The last directory server in the set.
LAST_DS_SERVER="${DJ_INSTANCE}-$last_ds.${DJ_INSTANCE}"

# We need to wait for the last DS instance in the set to be up before we can configure replication.
while true; do
    if search "$LAST_DS_SERVER"; then
            break
    fi
    sleep 30
done

echo "About to begin replication setup..."
#sleep 10

# Configure replication between host $1 and $2 using basedn $3
dsconfigure() {
  echo "Configuring $1 to replicate to $2"
$dsreplica configure \
     --adminUID "$ADMIN_ID" \
     --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
     --baseDN "$3" \
     --host1 "$1" --port1 4444 --replicationPort1 8989 \
     --bindDN1 "cn=Directory Manager" \
     --bindPasswordFile1 "${DIR_MANAGER_PW_FILE}" \
     --host2 "$2" --port2 4444 \
     --bindDN2 "cn=Directory Manager"  --replicationPort2 8989 \
     --bindPasswordFile2 "${DIR_MANAGER_PW_FILE}" \
     --no-prompt

     #      --trustAll \

}

# Set our purge delay to 8 hours. The default backup is every 30 minutes.
set_purge_delay() 
{
    # Sets replication purge delay
    /opt/opendj/bin/dsconfig set-replication-server-prop \
        --provider-name Multimaster\ Synchronization \
        --set replication-purge-delay:8\ h \
        --hostname "${1}" --bindPasswordFile ${DIR_MANAGER_PW_FILE} --port 4444 --trustAll --no-prompt       
}

# For each directory server starting at ds-1 to ds-last
for j in $(seq 1 $last_ds); do
    ds2="${DJ_INSTANCE}-$j.${DJ_INSTANCE}"
    dsconfigure "${FQDN_DS0}"  "$ds2" "$BASE_DN"
    dsconfigure "${FQDN_DS0}" "$ds2"  "o=cts"
    set_purge_delay "$ds2" 
done

set_purge_delay ${FQDN_DS0}

exit 0

echo "Initializing replication"

# Initiaize all -used on a fresh cluster with no data.
initall() {
    # Initialize replication of user data:
    /opt/opendj/bin/dsreplication initialize-all  \
        --adminUID "$ADMIN_ID" \
        --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
        --port 4444 \
        --hostname "${FQDN_DS0}" \
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
        --hostname "${FQDN_DS0}" \
          -b "$1" \
        --trustAll \
        --no-prompt
}

# todo: We want more flexibility here in how replication is initialized. Revist
initall "${BASE_DN}"
initall "o=cts"




