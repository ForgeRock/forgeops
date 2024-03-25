#!/usr/bin/env bash
# Export backends using ldif export
# This is done offline, and is expected to be run by a job that runs to termination

set -e
# The optional argument is the name of a directory to backup to. Defaults to /var/tmp
DIR=${1:-/var/tmp}

mkdir -p "$DIR"


# The DS server version needs to match the JE data version
echo "Upgrading configuration and data..."
./upgrade --dataOnly --acceptLicense --force --ignoreErrors --no-prompt


# Calculate the list of backends.
mapfile -t BACK_ENDS < <(./bin/ldifsearch -b cn=backends,cn=config -s one config/config.ldif "(&(objectclass=ds-cfg-pluggable-backend)(ds-cfg-enabled=true))" ds-cfg-backend-id | grep "^ds-cfg-backend-id" | cut -c20-)

echo "Backends ${BACK_ENDS[@]}"

for B in "${BACK_ENDS[@]}"; do
    F="$DIR/$B.ldif"

    if [[ "$B" =~ ^(rootUser|proxyUser|monitorUser|tasks|adminRoot)$ ]]; then
        echo "Skipping system backend $B"
    else
        echo "Backing up $B to $F"
        export-ldif --ldifFile $F --backendId $B --offline
    fi
done
