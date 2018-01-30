#!/usr/bin/env bash
# Set up a replication server.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
set -x

# First RS instance in the statefulset is -0:
RS0="${DJ_INSTANCE_RS}-0.${DJ_INSTANCE_RS}"


if echo $HOSTNAME | grep 0 ; then
    RS=""
else
 # If we are not node 0, set the additional arg to replicate to RS0.
 RS="--replicationServer $RS0:4444 --trustAll"
 # This is a bit of a hack. The first RS in the set may still be in the process of being configured. We
 # need to give it time to come up before we try to replicate to it.
 # todo: We should loop here and ping the server until it responds
 echo "Giving the first replication server time to start"
 # todo: We need a better method of testing for RS0 being up.
 sleep 90
fi


/opt/opendj/setup replication-server  \
  --adminConnectorPort 4444 \
  --instancePath ./data \
  --rootUserDN "cn=Directory Manager" --rootUserPassword "$PASSWORD" \
  --hostname "${RS_FQDN}" \
  --replicationPort 8989 \
  $RS \
  --acceptLicense \
   || (echo "Setup failed, will sleep for debugging"; sleep 10000)

