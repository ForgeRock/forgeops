#!/usr/bin/env bash
# Set up a proxy directory server.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

set -x


cd /opt/opendj

echo "Setting up Directory Proxy"

#PROXY_USER_DN="cn=proxy"
PROXY_USER_DN="cn=Directory Manager"

# This is an alternative to using symbolic links at the top level /opt/opendj directory.
# If you use this, your docker image must create an instanc.loc file that points to this directory.
#INSTANCE_PATH="--instancePath /opt/opendj/data"

# We could also specify --replicationServer "blah" for DPS to automatically discover DS instnaces
# to load balance but then this pod needs to be created after DS pods

# trustAll used until we get truststore working
#          --usePkcs12TrustStore "${KEYSTORE_FILE}" \
#       --trustStorePasswordFile "${KEYSTORE_PIN_FILE}" \
# We can supply this arg multiple times if we know the static list of servers
#        --staticPrimaryServer "ds-0.ds:1389" \
#        --staticPrimaryServer "ds-1.ds:1389" \


./setup proxy-server \
          --rootUserDn "cn=Directory Manager" \
          --rootUserPasswordFile "${DIR_MANAGER_PW_FILE}"  \
          --monitorUserDn "uid=Monitor" \
          --monitorUserPasswordFile "${DIR_MANAGER_PW_FILE}" \
          --hostname "${FQDN}" \
          --adminConnectorPort 4444 \
          --ldapPort 1389 \
          --ldapsPort 1636 \
          --httpPort 8080 \
          --httpsPort 8443 \
          --baseDN "${BASE_DN}" \
          --proxyUserBindDn "$PROXY_USER_DN" \
          --proxyUserBindPasswordFile "${DIR_MANAGER_PW_FILE}" \
          --loadBalancingAlgorithm affinity \
          --replicationServer "${FQDN_DS_0}:4444" \
          --replicationBindPasswordFile  "${DIR_MANAGER_PW_FILE}" \
          --replicationBindDn "cn=Directory Manager" \
          --acceptLicense \
          --doNotStart \
          --trustAll \
          || (echo "Setup failed, will sleep for debugging"; sleep 10000)
