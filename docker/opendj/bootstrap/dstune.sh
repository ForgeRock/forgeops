#!/usr/bin/env bash
# A simple script to tune OpenDJ
# Copyright (c) 2017-2018 ForgeRock AS. All rights reserved.


cd /opt/opendj

source env.sh 


DSCFG="bin/dsconfig"

COMMON="--offline --no-prompt"

sbp() 
{
		echo "Updating $2 for $1"
        $DSCFG set-backend-prop \
          $COMMON \
          --backend-name "$1" \
          --set "$2"
}

cec() 
{
        $DSCFG create-entry-cache \
          $COMMON \
          --backend-name "$1" \
          --type soft-reference \
          --set cache-level:1 \
          --set include-filter: "$2" \
          --set enabled:true
}

slpp() 
{
        $DSCFG set-log-publisher-prop \
          $COMMON \
          --publisher-name "$1" \
          --set enabled:false
}

schp() 
{
        $DSCFG set-connection-handler-prop \
          $COMMON \
          --handler-name "LDAP Connection Handler" \
          --set "$1" 
}

sbp "userRoot" "entries-compressed:true"

#sbp "userRoot" "db-cache-percent:70"
sbp "userRoot" "db-log-filecache-size:1000"
#sbp "userRoot" "db-log-file-max: 100 mb"
sbp "ctsRoot"  "db-durability:low"


