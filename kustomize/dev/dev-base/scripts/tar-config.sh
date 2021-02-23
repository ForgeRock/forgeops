#!/usr/bin/env bash
# Script to assist in exporting AM updated configuration

WORKSPACE="${WORKSPACE:-/git}"
REPO="fr-config"

# tars updated configuration ready for exporting
dest=${1:-"$WORKSPACE/placeholdered-config.tar.gz"}

cd "$WORKSPACE"
tar -cz "$REPO" -f $dest &
pid=$!
wait

while ps -f $pid >/dev/null
do
    echo "tar is still running"
    sleep 1
done
