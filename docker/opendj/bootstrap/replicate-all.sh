#!/usr/bin/env bash
#
# Initialize replication for the cluster.
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#

set -x


source /opt/opendj/env.sh


# It looks like the replication commands want the *local* server to be setup as well. Since we are
# running in a job, we create a very simple DS server.
/opt/opendj/setup directory-server -p 1389  \
  --adminConnectorPort 4444 \
  --instancePath ./data \
  --baseDN "$BASE_DN" -h localhost --rootUserPassword "$PASSWORD" \
  --acceptLicense \
   || (echo "Setup failed"; exit 1)





ADMIN_ID=admin

# Put an echo in front of this command if you just want to see what the script does.
dsreplica="/opt/opendj/bin/dsreplication"

if [ -z "$DS_SET_SIZE" ]; then
    echo "DS_SET_SIZE is not set!. We need to know how many DS nodes are in the statefulSet"
    exit 1
fi

# R0 is the FQDN of the first RS
R0="${DJ_INSTANCE}-rs-0.${DJ_INSTANCE}-rs"
let end="$DS_SET_SIZE - 1"

LAST_DS="${DJ_INSTANCE}-$end.${DJ_INSTANCE}"

env
# Search for an LDAP host. Return 0 if it is available.
search() {
    echo "Waiting for server $1 to be available"
    /opt/opendj/bin/ldapsearch -h "$1" -w "$PASSWORD" -p 1389 -D "cn=Directory Manager" \
     --baseDN "$BASE_DN" -s base -l 5 \
     "(objectClass=*)" 1.1
}

# We need to wait for the last DS instance in the set to be up
while true; do
    if search "$LAST_DS"; then
            break
    fi
    sleep 10
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


# Step one - enable replication on all DS servers, including -0
for i in $(seq 0 $end); do
    H="${DJ_INSTANCE}-$i.${DJ_INSTANCE}"

     $dsreplica configure \
     --adminUID "$ADMIN_ID" \
     --adminPassword "${PASSWORD}" \
     --baseDN "$BASE_DN" \
     --host1 "$H" \
     --port1 4444 \
     --bindDN1 "cn=Directory Manager" \
     --bindPassword1 "${PASSWORD}" \
     --noReplicationServer1 \
     --host2 "$R0" \
     --port2 4444 \
     --bindDN2 "cn=Directory Manager" \
     --bindPassword2 "${PASSWORD}" \
     --replicationPort2 8989 \
     --onlyReplicationServer2 \
     --trustAll \
     --no-prompt
done


# We initialize from the first server in the set.
H0="${DJ_INSTANCE}-0.${DJ_INSTANCE}"

# On each DS *other* than node 0, initialize replication
# Note this expression is bash - not sh
for i in $(seq 1 $end); do

    H="${DJ_INSTANCE}-$i.${DJ_INSTANCE}"

    $dsreplica initialize \
        --baseDN "$BASE_DN" \
        --hostSource "$H0" \
        --portSource 4444 \
        --hostDestination "${H}" \
        --portDestination 4444 \
        --trustAll \
        --no-prompt \
        --adminUID "$ADMIN_ID" \
        --adminPassword "${PASSWORD}"
done