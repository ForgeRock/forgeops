#!/usr/bin/env bash
# Run an amster script. This sets the VERSION for replacement in the configuration files.

echo "Extracting amster version"
VER=$(./amster --version)
[[ "$VER" =~ ([0-9].[0-9].[0-9](\.[0-9]*)?-([a-zA-Z][0-9]+|SNAPSHOT|RC[0-9]+)|[0-9].[0-9].[0-9](\.[0-9]*)?) ]]
VERSION=${BASH_REMATCH[1]}
echo "Amster version is: '${VERSION}'"
export VERSION

./amster $1


