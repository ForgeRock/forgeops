#!/usr/bin/env bash
# Sample utility to make a lot of users
cd /opt/opendj

USERS=1000000
START=0

export FQDN_DS0="${FQDN_DS0:-ds-idrepo-0.ds-idrepo}"
export ADMIN_PW="${ADMIN_PW:-password}"

BASE_DN="ou=identities"

[[ $# -eq 1 ]] && USERS=$1
[[ $# -eq 2 ]] && USERS=$1 && START=$2

echo "Making $USERS sample users"
bin/makeldif -o /var/tmp/l.ldif -c suffix=$BASE_DN -c numusers=$USERS config/MakeLDIF/example.template

bin/ldapmodify --hostname "${FQDN_DS0}" \
    --bindPassword "${ADMIN_PW}" \
    --bindDn "uid=admin" \
    --port 1389 \
    --no-prompt \
    --continueOnError \
    --numConnections 10 \
    /var/tmp/l.ldif

# For offline only:
# bin/import-ldif --templateFile /var/tmp/template --clearBackend \
#    --backendId amIdentityStore --tmpDirectory /opt/opendj/import-tmp --bindDn "cn=Directory Manager" \
#    --bindPasswordFile "$DIR_MANAGER_PW_FILE" --port 4444 --trustAll