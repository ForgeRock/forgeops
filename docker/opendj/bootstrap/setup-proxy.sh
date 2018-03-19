#!/usr/bin/env bash
# Set up a proxy directory server.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

#set -x

source /opt/opendj/env.sh

cd /opt/opendj


# This is an alternative to using symbolic links at the top level /opt/opendj directory.
# If you use this, your docker image must create an instanc.loc file that points to this directory.
#INSTANCE_PATH="--instancePath /opt/opendj/data"

# We could also specify --replicationServer "blah" for DPS to automatically discover DS instnaces
# to load balance but then this pod needs to be created after DS pods

/opt/opendj/setup proxy-server \
          --instancePath "${INSTANCE_PATH}" \
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
          --staticPrimaryServer "ds-0.ds:1389" \
          --proxyUserBindDn "cn=proxy" \
          --proxyUserBindPasswordFile "${DIR_MANAGER_PW_FILE}" \
          --loadBalancingAlgorithm affinity \
          || (echo "Setup failed, will sleep for debugging"; sleep 10000)

#--productionMode \
#--replicationServer "ds-0:8989" \
#--staticSecondaryServer "ds-1:1389" \


# Run any post installation scripts for the bootstrap type.
post_install_scripts() {
    script="bootstrap/${BOOTSTRAP_TYPE}/post-install.sh"

    if [ -r "$script" ]; then
        echo "executing post install script $script"
        sh "$script"
    fi
}



post_install_scripts

