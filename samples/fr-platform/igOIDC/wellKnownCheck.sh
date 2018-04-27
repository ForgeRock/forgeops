#!/bin/bash

while true; do
    STATUS=`curl -I $WELL_KNOWN_ENDPOINT  2>/dev/null | head -n 1 | cut -d$' ' -f2`
    echo $STATUS
    if [[ "$STATUS" == "200" ]]; then
      break
    fi
    sleep 10
done
