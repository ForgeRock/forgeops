#!/usr/bin/env bash

/opt/opendj/bin/dsconfig set-log-publisher-prop \
          --publisher-name Json\ File-Based\ Access\ Logger \
          --set enabled:false \
          --hostname localhost \
          --port 4444 \
          --bindDn cn=Directory\ Manager \
          --bindPasswordFile ${DIR_MANAGER_PW_FILE} \
          --trustAll \
          --no-prompt