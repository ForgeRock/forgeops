#!/usr/bin/env bash
#
# Configure and Initialize replication for the cluster.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# This should be run from the admin server node.
#set -x


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
let last_rs="$RS_SET_SIZE - 1"

LAST_DS_SERVER="${DJ_INSTANCE}-$last_ds.${DJ_INSTANCE}"

# We need to wait for the last DS instance in the set to be up
while true; do
    if search "$LAST_DS_SERVER"; then
            break
    fi
    sleep 30
done

# We need at least RS0 to be up...
# The search() function does not work on an RS. So we need to find a better check.
#while true; do
#    if search "$R0"; then
#        break
#    fi
#    sleep 10
#done


echo "About to begin replication setup"

# First tell the two RS servers about each other

R0="${DJ_INSTANCE}-rs-0.${DJ_INSTANCE}-rs"
R1="${DJ_INSTANCE}-rs-1.${DJ_INSTANCE}-rs"

echo "Introducing $R0 to $R1"

# This is now being done as part of setup - but lets keep this around until we
# decide if this is a better place to configure it.
#/opt/opendj/bin/dsreplication configure \
# --baseDN "$BASE_DN" \
# --adminUID "$ADMIN_ID" \
# --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
# --host1 "$R0" \
# --port1 4444 \
# --replicationPort1 8989 \
# --bindDN1 "cn=Directory Manager" \
# --bindPasswordFile1 "${DIR_MANAGER_PW_FILE}" \
# --onlyReplicationServer1 \
# --host2 "$R1" \
# --port2 4444 \
# --bindDN2 "cn=Directory Manager" \
# --bindPasswordFile2 "${DIR_MANAGER_PW_FILE}" \
# --replicationPort2 8989 \
# --onlyReplicationServer2 \
# --trustAll \
# --no-prompt

# arguments: $1 - the ds host to replicate, $2 - the RS server instance to replicate to.
dsconfigure() {
  echo "Configuring DS $1 to replicate to RS $2"
  $dsreplica configure \
     --adminUID "$ADMIN_ID" \
     --adminPasswordFile "${DIR_MANAGER_PW_FILE}" \
     --baseDN "$BASE_DN" \
     --host1 "$1" \
     --port1 4444 \
     --bindDN1 "cn=Directory Manager" \
     --bindPasswordFile1 "${DIR_MANAGER_PW_FILE}" \
     --noReplicationServer1 \
     --host2 "$2" \
     --port2 4444 \
     --bindDN2 "cn=Directory Manager" \
     --bindPasswordFile2 "${DIR_MANAGER_PW_FILE}" \
     --replicationPort2 8989 \
     --onlyReplicationServer2 \
     --trustAll \
     --no-prompt
}

# For each replica server..
for replica in $(seq 0 $last_rs); do
  R="${DJ_INSTANCE}-rs-$replica.${DJ_INSTANCE}-rs"
  for dsserver in $(seq 0 $last_ds); do
    H="${DJ_INSTANCE}-$dsserver.${DJ_INSTANCE}"
    dsconfigure "${H}" "${R}"
  done
  # This admin server is also a DS, so we need to setup replication to it.
   dsconfigure "${FQDN}"  "${R}"
done



# Initialize replication
/opt/opendj/bootstrap/replicate-init.sh

