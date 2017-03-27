#!/usr/bin/env sh
# Configure external CTS store OpenDJ instance.
# See https://wikis.forgerock.org/confluence/display/openam/Configure+External+CTS

cd /opt/opendj

# For the CTS store, we fix to a known base DN, port, directory manager.
# The script that calls us should set the $PASSWORD environment variable.
BASE_DN="dc=openam,dc=forgerock,dc=org"
SERVER_PORT=389
USER="cn=Directory Manager"

/opt/opendj/setup -p $SERVER_PORT  \
  --adminConnectorPort 4444 \
  --baseDN $BASE_DN -h localhost --rootUserPassword "$PASSWORD" \
  --acceptLicense --addBaseEntry

SRC=bootstrap/cts/sfha

T=/tmp/ldif
rm -rf $T
mkdir $T
cp $SRC/cts-add-schema.ldif $T/cts-add-schema.ldif
cp $SRC/cts-add-multivalue.ldif $T/cts-add-multivalue.ldif
cat $SRC/cts-add-multivalue-indices.ldif | sed -e 's/@DB_NAME@/userRoot/' > $T/cts-add-multivalue-indices.ldif
cat $SRC/cts-indices.ldif | sed -e 's/@DB_NAME@/userRoot/' > $T/cts-indices.ldif
cat $SRC/cts-container.ldif | sed -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/" > $T/cts-container.ldif
bin/ldapmodify --port $SERVER_PORT --bindDN "$USER" --bindPassword "$PASSWORD" --fileName $T/cts-add-schema.ldif
bin/ldapmodify --port $SERVER_PORT --bindDN "$USER" --bindPassword "$PASSWORD" --fileName $T/cts-indices.ldif
bin/ldapmodify --port $SERVER_PORT --bindDN "$USER" --bindPassword "$PASSWORD" --fileName $T/cts-container.ldif
bin/ldapmodify --port $SERVER_PORT --bindDN "$USER" --bindPassword "$PASSWORD" --fileName $T/cts-add-multivalue.ldif
bin/ldapmodify --port $SERVER_PORT --bindDN "$USER" --bindPassword "$PASSWORD" --fileName $T/cts-add-multivalue-indices.ldif

# Optional - turn off sync writes.
# This is experimental -
# This setting made little difference in CTS performance (10-15 %).
echo "Tuning sync writes for OpenDJ"
bin/dsconfig  --trustAll -w "$PASSWORD" -h localhost --bindDN "cn=Directory Manager" set-backend-prop \
          --backend-name userRoot \
          --set db-txn-no-sync:true \
          --set db-txn-write-no-sync:false \
          --no-prompt

# Access logs do not add a lot of value for the CTS store.
echo "Disabling CTS store access log"

bin/dsconfig --trustAll -w "$PASSWORD" -h localhost --bindDN "cn=Directory Manager" set-log-publisher-prop \
          --publisher-name Json\ File-Based\ Access\ Logger \
          --set enabled:false \
          --no-prompt

bin/stop-ds
bin/rebuild-index --baseDN $BASE_DN --rebuildAll --offline
bin/verify-index --baseDN $BASE_DN
