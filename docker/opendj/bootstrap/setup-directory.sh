#!/usr/bin/env bash
# Set up a directory server.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

#set -x

source /opt/opendj/env.sh

cd /opt/opendj


INIT_OPTION="--addBaseEntry"

# If NUMBER_SAMPLE_USERS is set AND we are the first node, then generate sample users.
if [[  -n "${NUMBER_SAMPLE_USERS}" && $HOSTNAME = *"0"* ]]; then
    INIT_OPTION="--sampleData ${NUMBER_SAMPLE_USERS}"
fi

# This is an alternative to using symbolic links at the top level /opt/opendj directory.
# If you use this, your docker image must create an instanc.loc file that points to this directory.
#INSTANCE_PATH="--instancePath /opt/opendj/data"

# An admin server is also a directory server.
/opt/opendj/setup directory-server\
  -p 1389 \
  --enableStartTLS  \
  --adminConnectorPort 4444 \
  --enableStartTls \
  --ldapsPort 1636 \
  --httpPort 8080 --httpsPort 8443 \
  --baseDN "${BASE_DN}" -h "${FQDN}" \
  --rootUserPasswordFile "${DIR_MANAGER_PW_FILE}" \
  --acceptLicense \
  ${INSTANCE_PATH} \
  ${INIT_OPTION} || (echo "Setup failed, will sleep for debugging"; sleep 10000)



# Load any optional LDIF files
load_ldif() {
    # If any optional LDIF files are present, load them.
    ldif="bootstrap/${BOOTSTRAP_TYPE}/ldif"

    if [ -d "$ldif" ]; then
        echo "Loading LDIF files in $ldif"
        for file in "${ldif}"/*.ldif;  do
            echo "Loading $file"
            # search + replace all placeholder variables. Naming conventions are from AM.
            sed -e "s/@BASE_DN@/$BASE_DN/"  \
                -e "s/@userStoreRootSuffix@/$BASE_DN/"  \
                -e "s/@DB_NAME@/$DB_NAME/"  \
                -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/"  <${file}  >/tmp/file.ldif

            ./bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -j ${DIR_MANAGER_PW_FILE} -f /tmp/file.ldif
          echo "  "
        done
    fi
}



# Run any post installation scripts for the bootstrap type.
post_install_scripts() {
    script="bootstrap/${BOOTSTRAP_TYPE}/post-install.sh"

    if [ -r "$script" ]; then
        echo "executing post install script $script"
        sh "$script"
    fi
}


# Load any optional ldif files
load_ldif

post_install_scripts

