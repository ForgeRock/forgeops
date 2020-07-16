#!/usr/bin/env bash
# Script to assist in exporting AM configuration

cd /home/forgerock/openam

# Get a list of files that have changed. Prune boot.json as we can ignore.
git diff --name-only | grep -v boot.json  >/var/tmp/export-list

# tar destination defaults to /home/forgerock/updated-config.tar
# Pass `-` as the argument to output the tar stream to stdout. Use kubectl exec am-pod -- export.sh - > tar.out
dest=${1:-"/home/forgerock/updated-config.tar"}

tar -c --files-from=/var/tmp/export-list -f $dest