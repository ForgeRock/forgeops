#!/usr/bin/env bash
# Sample utility to make a lot of users
cd /opt/opendj

source env.sh 

USERS=1000000
START=0

[[ $# -eq 1 ]] && USERS=$1
[[ $# -eq 2 ]] && USERS=$1 && START=$2

echo "Making $USERS sample users"

cat <<EOF >/var/tmp/template
define suffix=$BASE_DN
define maildomain=example.com
define numusers=$USERS

branch: [suffix]
objectClass: top
objectClass: organization

branch: ou=People,[suffix]
objectClass: top
objectClass: organizationalUnit
subordinateTemplate: person:[numusers]

branch: ou=Groups,[suffix]
objectClass: top
objectClass: organizationalUnit

template: person
rdnAttr: uid
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
givenName: <first>
sn: <last>
cn: {givenName} {sn}
initials: {givenName:1}<random:chars:ABCDEFGHIJKLMNOPQRSTUVWXYZ:1>{sn:1}
employeeNumber: <sequential:$START>
uid: user.{employeeNumber}
mail: {uid}@[maildomain]
userPassword: password
telephoneNumber: <random:telephone>
homePhone: <random:telephone>
pager: <random:telephone>
mobile: <random:telephone>
street: <random:numeric:5> <file:streets> Street
l: <file:cities>
st: <file:states>
postalCode: <random:numeric:5>
postalAddress: {cn}${street}${l}, {st}  {postalCode}
description: This is the description for {cn}.
EOF

bin/makeldif  -o /var/tmp/l.ldif  /var/tmp/template

bin/ldapmodify --hostname "${FQDN_DS0}" \
    --bindPasswordFile "${DIR_MANAGER_PW_FILE}" \
    --bindDn "cn=Directory Manager" \
    --port 1389 \
    --no-prompt \
    --continueOnError \
    --numConnections 10 \
    /var/tmp/l.ldif

# For offline only:
# bin/import-ldif --templateFile /var/tmp/template --clearBackend \
#    --backendId amIdentityStore --tmpDirectory /opt/opendj/import-tmp --bindDn "cn=Directory Manager" \
#    --bindPasswordFile "$DIR_MANAGER_PW_FILE" --port 4444 --trustAll
