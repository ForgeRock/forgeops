#!/usr/bin/env bash
# Script to assist in exporting AM updated configuration

# tars updated configuration ready for exporting
dest=${1:-"/am-config/config/placeholdered-config.tar"}

cd "/am-config"
tar -c "config/services" -f $dest &
pid=$!
wait

while ps -f $pid >/dev/null
do
    echo "tar is still running"
    sleep 1
done