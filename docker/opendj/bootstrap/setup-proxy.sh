#!/usr/bin/env bash
# Set up a proxy directory server.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

set -x


cd /opt/opendj

echo "Setting up Directory Proxy"
PROXY_USER_DN="uid=proxy,ou=admins,$BASE_DN"
# Todo: We need a better way of parameterizing the proxy user

# todo: 
# We need to set the proxy users password on install. We should change it in ds-0 before running setup

# This is an alternative to using symbolic links at the top level /opt/opendj directory.
# If you use this, your docker image must create an instanc.loc file that points to this directory.
#INSTANCE_PATH="--instancePath /opt/opendj/data"

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
          --proxyUserBindDn "${PROXY_USER_DN}" \
          --proxyUserBindPasswordFile "${DIR_MANAGER_PW_FILE}" \
          --loadBalancingAlgorithm affinity \
          --replicationServer "${FQDN_DS_0}:4444" \
          --replicationBindPasswordFile  "${DIR_MANAGER_PW_FILE}" \
          --replicationBindDn "cn=Directory Manager" \
          --acceptLicense \
          --baseDN "${BASE_DN}" \
          --doNotStart \
          --trustAll \
          || (echo "Setup failed, will sleep for debugging"; sleep 10000)


#   --hostname "localhost"  \
#         --port 4444  \
#         --bindDN "cn=Directory Manager" \
#         --bindPasswordFile "${DIR_MANAGER_PW_FILE}" \
# See https://backstage.forgerock.com/docs/ds/6/admin-guide/#chap-proxy
createbackend() 
{
    P=`cat $DIR_MANAGER_PW_FILE`

    bin/dsconfig create-backend  \
        --offline \
        --backend-name $2  \
        --type proxy  \
        --set enabled:true \
        --set "base-dn:${1}" \
        --set route-all:false \
        --set load-balancing-algorithm:affinity  \
        --set proxy-user-dn:"cn=Directory Manager" \
        --set proxy-user-password:$P \
        --set service-discovery-mechanism:"Replication Service Discovery Mechanism" \
        --no-prompt
}

# createbackend "$BASE_DN" userstore 
# createbackend o=cts cts
