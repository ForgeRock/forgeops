#!/usr/bin/env sh

# Optional - turn off sync writes.
# This is experimental -
# This setting made little difference in CTS performance (10-15 %).
# These no longer apply to the new JE backend.
#echo "Tuning sync writes for OpenDJ"
#bin/dsconfig  --trustAll -w "$PASSWORD" -h localhost --bindDN "cn=Directory Manager" --port 4444 set-backend-prop \
#  --backend-name userRoot \
#  --set db-txn-write-no-sync:false \
#  --no-prompt

# Access logs do not add a lot of value for the CTS store.
echo "Disabling CTS store access log"

/opt/opendj/bin/dsconfig set-log-publisher-prop \
          --offline \
          --publisher-name Json\ File-Based\ Access\ Logger \
          --set enabled:false \
          --no-prompt