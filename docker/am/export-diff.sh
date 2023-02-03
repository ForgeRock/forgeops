#!/usr/bin/env bash
# Script to assist in exporting AM configuration
# Like export.sh - but only exports files that have changed

set -o errexit

git config --global --add safe.directory /home/forgerock/openam

cd /home/forgerock/openam

if [ "$1" = "--deleted" ]; then
    # Get a list of files that have been deleted.
    git diff --name-only --diff-filter=D
    exit 0
fi

# Adds any new file so it shows up with git diff
git add -N config

# Get a list of files that have changed. Prune boot.json as we can ignore.
git diff --name-only | grep -v boot.json  >/var/tmp/export-list || exit 0

# tar destination defaults to /home/forgerock/updated-config.tar
# Pass `-` as the argument to output the tar stream to stdout. Use kubectl exec am-pod -- export.sh - > tar.out
dest=${1:-"/home/forgerock/updated-config.tar"}

tar -c --files-from=/var/tmp/export-list -f $dest
