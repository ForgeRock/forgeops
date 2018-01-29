#!/bin/bash

while true; do
    wget -O /dev/null $WELL_KNOWN_ENDPOINT
    if [[ "$?" -eq 0 ]]; then
      break
    fi
    sleep 10
done
