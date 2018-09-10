#!/usr/bin/env bash
# Arg $1 "true" or "false" to enable or disable replication

# Disable replication
bin/dsconfig set-replication-domain-prop \
         --provider-name Multimaster\ Synchronization \
         --domain-name o=idm \
         --set enabled:$1 \
         --hostname localhost \
         --port 4444 \
         --bindDn cn=Directory\ Manager \
         --trustAll \
         --bindPasswordFile $DIR_MANAGER_PW_FILE \
         --no-prompt