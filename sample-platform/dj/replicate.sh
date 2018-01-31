#!/usr/bin/env bash
#  Enable replication on a single DS server
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#

set -x

# This should only be run on directory servers
if [ "${DS_ROLE}" != "directory-server" ]; then
    echo "Not running on a directory server. Nothing to do."
    exit 0
fi

# If we are running in an interactive shell via exec - password might not be set.
if [ -z "${PASSWORD}"  ]; then
    PW=`cat $DIR_MANAGER_PW_FILE`
    PASSWORD=${PW:-password}
fi

# Needed??
ADMIN_ID=admin
#ADMIN_ID="cn=Directory Manager"

# H is our own FQDN
H="${HOSTNAME}.${DJ_INSTANCE}"
# R1 is the FQDN of the first RS
R1="${DJ_INSTANCE}-rs-0.${DJ_INSTANCE}-rs"

# fork added this:
# -b "dc=openidm,dc=forgerock,dc=com" \
/opt/opendj/bin/dsreplication configure \
 --adminUID "$ADMIN_ID" \
 --adminPassword "${PASSWORD}" \
 --baseDN "$BASE_DN" \
 -b "dc=openidm,dc=forgerock,dc=com" \
 --host1 "$H" \
 --port1 4444 \
 --bindDN1 "cn=Directory Manager" \
 --bindPassword1 "${PASSWORD}" \
 --noReplicationServer1 \
 --host2 "$R1" \
 --port2 4444 \
 --bindDN2 "cn=Directory Manager" \
 --bindPassword2 "${PASSWORD}" \
 --replicationPort2 8989 \
 --onlyReplicationServer2 \
 --trustAll \
 --no-prompt


# There must be at least two DS servers to initialize. Only run this if we are the second or higher.
# Note this expression is bash - not sh
if [[ "$HOSTNAME" != *"-0"* ]];  then
    # We initialize from the first server in the set.
    H0="${DJ_INSTANCE}-0.${DJ_INSTANCE}"

    # fork added this:
    # -b "dc=openidm,dc=forgerock,dc=com" \
    /opt/opendj/bin/dsreplication initialize \
        --baseDN "$BASE_DN" \
        -b "dc=openidm,dc=forgerock,dc=com" \
        --hostSource "$H0" \
        --portSource 4444 \
        --hostDestination "${H1}" \
        --portDestination 4444 \
        --trustAll \
        --no-prompt \
        --adminUID admin \
        --adminPassword "${PASSWORD}"
fi
