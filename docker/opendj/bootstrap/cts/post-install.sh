#!/usr/bin/env sh

cd /opt/opendj

set +x

source /opt/opendj/env.sh


# Optional - turn off sync writes.
# This is experimental -
# This setting made little difference in CTS performance (10-15 %).
echo "Tuning sync writes for OpenDJ"
bin/dsconfig  --trustAll -w "$PASSWORD" -h localhost --bindDN "cn=Directory Manager" --port 4444 set-backend-prop \
  --backend-name userRoot \
  --set db-txn-no-sync:true \
  --set db-txn-write-no-sync:false \
  --no-prompt

# Access logs do not add a lot of value for the CTS store.
echo "Disabling CTS store access log"

bin/dsconfig --trustAll -w "$PASSWORD" -h localhost --bindDN "cn=Directory Manager" set-log-publisher-prop --port 4444 \
          --publisher-name Json\ File-Based\ Access\ Logger \
          --set enabled:false \
          --no-prompt

bin/stop-ds
bin/rebuild-index --baseDN $BASE_DN --rebuildAll --offline
bin/verify-index --baseDN $BASE_DN
