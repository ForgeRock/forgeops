#!/usr/bin/env sh
# Default setup script
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

echo "Setting up default OpenDJ instance."

cd /opt/opendj

touch /opt/opendj/BOOTSTRAPPING

DB_NAME=${DB_NAME:-userRoot}

# The type of DJ we want to bootstrap. This determines the ldif files and scripts to load. Defaults to a userstore.
BOOTSTRAP_TYPE="${BOOTSTRAP_TYPE:-userstore}"

INIT_OPTION="--addBaseEntry"

# If NUMBER_SAMPLE_USERS is set we generate sample users.
if [ -n "${NUMBER_SAMPLE_USERS+set}" ]; then
    INIT_OPTION="--sampleData ${NUMBER_SAMPLE_USERS}"
fi

# todo: We may want to specify a keystore using --usePkcs12keyStore, --useJavaKeystore
/opt/opendj/setup -p 1389 \
  --adminConnectorPort 4444 \
  --instancePath /opt/opendj/data \
  --baseDN $BASE_DN -h localhost --rootUserPassword "$PASSWORD" \
  --acceptLicense -b "dc=openidm,dc=forgerock,dc=com" \
  ${INIT_OPTION}

/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
   --provider-name "IDM managed/role Json Schema" \
   --type json-schema \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchManagedRole \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.2  \
   --set indexed-field:"condition/**" \
   --set indexed-field:"temporalConstraints/**" \
   --trustAll \
   --no-prompt

/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
   --provider-name "IDM Relationship Json Schema" \
   --type json-schema \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchRelationship \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.3  \
   --set indexed-field:firstId \
   --set indexed-field:firstPropertyName \
   --set indexed-field:secondId \
   --set indexed-field:secondPropertyName \
   --trustAll \
   --no-prompt

/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
   --provider-name "IDM Cluster Object Json Schema" \
   --type json-schema \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchClusterObject \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.4  \
   --set indexed-field:"timestamp" \
   --set indexed-field:"state" \
   --trustAll \
   --no-prompt

/opt/opendj/bin/stop-ds

cp -r /tmp/schema/* /opt/opendj/data/config/schema

/opt/opendj/bin/start-ds

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


/opt/opendj/schedule_backup.sh

/opt/opendj/rebuild.sh
