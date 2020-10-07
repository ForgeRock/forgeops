#!/usr/bin/env bash
# Script to assist in exporting AM updated configuration

# tars updated configuration ready for exporting
# Pass `-` as the argument to output the tar stream to stdout. Use kubectl exec am-config-upgrader-pod -- export.sh - > tar.out
dest=${1:-"/am-config/config/placeholdered-config.tar"}

cd "/am-config"
tar -cv "config" -f $dest