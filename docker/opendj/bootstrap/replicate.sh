#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Replicate to the master server hostname defined in $1.
# If that server is ourself, this is a no-op.

MASTER=$1

# This is a bit kludgy:
# The hostname has to be a fully resolvable DNS name in the cluster
# if the service is called.

MYHOSTNAME=`hostname -f`

echo "Setting up replication from $MYHOSTNAME to $MASTER"

# For debug:

# Kubernetes puts the service name in /etc/hosts
if grep ${MASTER} /etc/hosts; then
 echo "We are the master. Skipping replication setup to ourselves."
 exit 0
fi

# Comment out:
echo "Replicate ENV vars:"
env

echo "Enabling replication."

# todo: Replace with command to test for master being reachable and up:
echo "Will sleep for a bit to ensure master is up."

sleep 30

bin/dsreplication enable --host1 $MYHOSTNAME --port1 4444 \
  --bindDN1 "cn=directory manager" \
  --bindPassword1 $PASSWORD --replicationPort1 8989 \
  --host2 $MASTER --port2 4444 --bindDN2 "cn=directory manager" \
  --bindPassword2 $PASSWORD --replicationPort2 8989 \
  --adminUID admin --adminPassword $PASSWORD --baseDN $BASE_DN -X -n

echo "Initializing replication."

bin/dsreplication initialize --baseDN $BASE_DN \
  --adminUID admin --adminPassword $PASSWORD \
  --hostSource $MASTER --portSource 4444 \
  --hostDestination $MYHOSTNAME --portDestination 4444 -X -n

