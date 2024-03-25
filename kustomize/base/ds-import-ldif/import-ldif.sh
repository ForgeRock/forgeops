#!/usr/bin/env bash
# Import ldif files.
# This is done offline, and is expected to be run by a job that runs to termination.
# The first argument ($1) is the directory to search for the ldif file
# If the backendId ($2) is not  provided, all backends found in the directory will be restored. Otherwise just the
# specified backend is restored.

set -ex

if [[ "$#" -lt 1 ]]; then
    echo "usage: $0 directory backendId"
    exit 1
fi

DIR="$1"

[ -d "$DIR" ] || {
    echo "Directory $DIR DOES NOT exist."
    exit 1
}

BACKEND="${2:-all}"

if [[ $BACKEND == "all" ]]; then
    # Strip the .ldif from the filename
    BACKEND=$(cd $DIR; ls | sed -e s/\.ldif//g )
fi

echo "Backends to restore $BACKEND"

# Make sure the DS version matches any backend JE data
echo "Upgrading configuration and data..."
./upgrade --dataOnly --acceptLicense --force --ignoreErrors --no-prompt


for B in $BACKEND
do
    # Import the data.
    F="${DIR}/$B.ldif"
    echo "Importing $F to $B"
    import-ldif -F --ldifFile  "$F" --backendId $B --offline
done
