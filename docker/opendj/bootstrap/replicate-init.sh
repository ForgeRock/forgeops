#!/usr/bin/env bash
# Initialize replication. Assumes replication is already configured, and all servers are up


source /opt/opendj/env.sh


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

# We initialize from the first server in the set.
H0="${DJ_INSTANCE}-0.${DJ_INSTANCE}"

ds_init() {
 echo "Initialize replication for server $1"
 $dsreplica initialize \
        --baseDN "$BASE_DN" \
        --hostSource "$H0" \
        --portSource 4444 \
        --hostDestination "${1}" \
        --portDestination 4444 \
        --trustAll \
        --no-prompt \
        --adminUID "$ADMIN_ID" \
        --adminPasswordFile "${DIR_MANAGER_PW_FILE}"
}
# On each DS *other* than node 0, initialize replication
# Note this expression is bash - not sh
for i in $(seq 1 $end); do
    ds_init "${DJ_INSTANCE}-$i.${DJ_INSTANCE}"
done

# Also initialize ourself (the admin server) - since we need a copy of the data for backup
ds_init "${FQDN}"

echo "Generated logs"
cat /tmp/opendj-replication*
