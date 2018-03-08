#!/usr/bin/env bash
# Set up a replication server.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
source /opt/opendj/env.sh


# First RS instance in the statefulset is -0:
RS0="${DJ_INSTANCE}-rs-0.${DJ_INSTANCE}-rs"
#
# # If we are *NOT* RS 0, set the additional arg to replicate to the first RS server (RS0).
if echo $HOSTNAME | grep "\-0" ; then
    RS=""
else
    RS="--replicationServer $RS0:4444 --trustAll"
    # this is a hack. We should find a better way to test if the first RS is ready to replicate
    # todo: Can we delay introducing the two RS servers?
    sleep 90
fi

# Note: $RS must be unquoted so the shell expands it
/opt/opendj/setup replication-server  \
  --adminConnectorPort 4444 \
  --rootUserDN "cn=Directory Manager" \
  --rootUserPasswordFile "$DIR_MANAGER_PW_FILE" \
  --hostname "${FQDN}" \
  --replicationPort 8989 \
  $RS \
  --acceptLicense \
   || (echo "Setup failed, will sleep for debugging"; sleep 10000)
