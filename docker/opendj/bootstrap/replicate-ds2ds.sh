#!/usr/bin/env bash
# Configure and Initialize replication for the cluster - assumes that the
# directory servers are also replication servers.
#
# Copyright (c) 2017-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#


source /opt/opendj/env.sh

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


let last_ds="$DS_SET_SIZE - 1"


# First directory server in the set
DS0="${DJ_INSTANCE}-0.${DJ_INSTANCE}"
# The last directory server in the set.
LAST_DS_SERVER="${DJ_INSTANCE}-$last_ds.${DJ_INSTANCE}"

# We need to wait for the last DS instance in the set to be up before we can configure replication.
while true; do
    if search "$LAST_DS_SERVER"; then
            break
    fi
    sleep 30
done

# For good measure...
echo "About to begin replication setup in 30 seconds..."

sleep 30


# Configure replication between host $1 and $2 using basedn $3
dsconfigure() {
  echo "Configuring $1 to replicate to $2"
  $dsreplica configure \
     --adminUID "$ADMIN_ID" \
     --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
     --baseDN "$3" \
     --host1 "$1" \
     --port1 4444 \
     --bindDN1 "cn=Directory Manager" \
     --bindPasswordFile1 "${DIR_MANAGER_PW_FILE}" \
     --replicationPort1 8989 \
     --host2 "$2" \
     --port2 4444 \
     --bindDN2 "cn=Directory Manager" \
     --bindPasswordFile2 "${DIR_MANAGER_PW_FILE}" \
     --replicationPort2 8989 \
     --trustAll \
     --no-prompt
}

# For each directory server starting at ds-1 to ds-last
for j in $(seq 1 $last_ds); do
    dsconfigure "${DS0}" "${DJ_INSTANCE}-$j.${DJ_INSTANCE}" "$BASE_DN"
    dsconfigure "${DS0}" "${DJ_INSTANCE}-$j.${DJ_INSTANCE}" "o=cts"
done

/opt/opendj/bootstrap/replicate-init.sh


