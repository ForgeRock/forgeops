#!/usr/bin/env sh
# Script to rebuild indexes. If you find the DJ indexes are degraded, exec
# into the container and run this command.

bin/rebuild-index \
 --port 4444 \
 --hostname localhost \
 --bindDN "cn=Directory Manager" \
 --bindPasswordFile "${DIR_MANAGER_PW_FILE}" \
 --baseDN "${BASE_DN}" \
 --rebuildDegraded \
 --trustAll

bin/rebuild-index \
 --port 4444 \
 --hostname localhost \
 --bindDN "cn=Directory Manager" \
 --bindPasswordFile "${DIR_MANAGER_PW_FILE}" \
 --baseDN "o=idm" \
 --rebuildDegraded \
 --trustAll
