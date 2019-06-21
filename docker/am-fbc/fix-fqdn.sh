#!/usr/bin/env bash
# Usage: ./fix-fqdn source_fqdn target_fqdn 

FQDN="${1:-default.iam.forgeops.com}"
REPLACE="${2:-test.iam.forgeops.com}"

# On mac use gsed
SED=sed
which gsed &>/dev/null && SED=gsed

find ./tmp/config -type f -name \*json -exec "${SED}" -i -e "s/${FQDN}/${REPLACE}/g" {} \;


echo "Files with pattern matching $REPLACE:"
find ./tmp/config -type f -name \*json -print0  | xargs -0 grep "${REPLACE}"

