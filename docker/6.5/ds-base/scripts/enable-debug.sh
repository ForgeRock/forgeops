#!/usr/bin/env bash
# Sample script to enable debug logging. Edit the target-name below with the package name you want to debug.

bin/dsconfig create-debug-target \
    --publisher-name "File-Based Debug Logger" \
    --type generic \
    --target-name org.opends.server.replication.server.changelog.file \
    --set enabled:true \
    --set include-throwable-cause:true \
    --hostname localhost \
    --port 4444 \
    --bindDn cn=Directory\ Manager \
    --bindPasswordFile $DIR_MANAGER_PW_FILE \
    --trustAll \
    --no-prompt

bin/dsconfig set-log-publisher-prop \
    --publisher-name "File-Based Debug Logger" \
    --set enabled:true \
    --hostname localhost \
    --port 4444 \
    --bindDn cn=Directory\ Manager \
    --bindPasswordFile $DIR_MANAGER_PW_FILE \
    --trustAll \
    --no-prompt

# List the debug targets..
bin/dsconfig list-debug-targets \
          --publisher-name File-Based\ Debug\ Logger \
          --hostname localhost \
          --port 4444 \
          --bindDn cn=Directory\ Manager \
          --bindPasswordFile $DIR_MANAGER_PW_FILE \
          --trustAll \
          --no-prompt
