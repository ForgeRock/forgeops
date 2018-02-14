#!/usr/bin/env bash
# Set up a directory server.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

#set -x

DB_NAME=${DB_NAME:-userRoot}

# The type of DJ we want to bootstrap. This determines the ldif files and scripts to load. Defaults to a userstore.
BOOTSTRAP_TYPE="${BOOTSTRAP_TYPE:-userstore}"

INIT_OPTION="--addBaseEntry"

# If NUMBER_SAMPLE_USERS is set AND we are the first node, then generate sample users.
if [[  -n "${NUMBER_SAMPLE_USERS}" && $HOSTNAME = *"0"* ]]; then
    INIT_OPTION="--sampleData ${NUMBER_SAMPLE_USERS}"
fi


# todo: We may want to specify a keystore using --usePkcs12keyStore, --useJavaKeystore
/opt/opendj/setup directory-server -p 1389 --ldapsPort 1636 --enableStartTLS  \
  --adminConnectorPort 4444 \
  --instancePath ./data \
  --baseDN "$BASE_DN" -h "${DJ_FQDN}" \
  --rootUserPassword "$PASSWORD" \
  --acceptLicense \
  ${INIT_OPTION} || (echo "Setup failed, will sleep for debugging"; sleep 10000)


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

        ./bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -w ${PASSWORD} -f /tmp/file.ldif
      echo "  "
    done
fi

script="bootstrap/${BOOTSTRAP_TYPE}/post-install.sh"

if [ -r "$script" ]; then
    echo "executing post install script $script"
    sh "$script"
fi

# todo: Move the backup setup to a job.
/opt/opendj/schedule_backup.sh

/opt/opendj/rebuild.sh

