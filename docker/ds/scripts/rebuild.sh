#!/usr/bin/env bash
# Script to rebuild indexes. If you find the DS indexes are degraded, exec
# into the container and run this command.

echo "Rebuilding indexes"

bin/rebuild-index \
 --port 4444 \
 --hostname localhost \
 --bindDN "cn=Directory Manager" \
 --bindPassword `cat ${DIR_MANAGER_PW_FILE}` \
 --baseDN "${BASE_DN}" \
 --rebuildDegraded \
 --trustAll
