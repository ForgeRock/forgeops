#!/usr/bin/env bash
# Sample utility to make a lot of bulk users.
# Usage:  make-users.sh number-users
cd /opt/opendj

USERS=10
BASE_DN="ou=identities"
START=0
BASE_DN="ou=identities"
BACKEND=amIdentityStore

# TODO: Is there a need to start at non zero?
[[ $# -eq 1 ]] && USERS=$1
[[ $# -eq 2 ]] && USERS=$1 && START=$2

# The value below is "password" encoded with PBKDF2
# {PBKDF2-HMAC-SHA256}10000:xKsMmlzVLRYdYzcgBuD3ZIAeSj8tNhjDHGFDqhth8Kcbw5qjL5UZxaiS2awL1HjO
# The template below is the same as config/MakeLDIF/example.template, execpt the userPassword is pre-encoded
cat <<EOF >/var/tmp/user.template
define suffix=ou=identities
define maildomain=example.com
define numusers=10000

branch: [suffix]
objectClass: top
objectClass: domain

branch: ou=People,[suffix]
objectClass: top
objectClass: organizationalUnit
subordinateTemplate: person:[numusers]

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
employeeNumber: <sequential:0>
uid: user.{employeeNumber}
mail: {uid}@[maildomain]
userPassword: \{PBKDF2-HMAC-SHA256\}10000:xKsMmlzVLRYdYzcgBuD3ZIAeSj8tNhjDHGFDqhth8Kcbw5qjL5UZxaiS2awL1HjO
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

# In order to preserve the backend, we need to export the existing entries
# If you dont do this the backend will not start.
rm -f data/var/users.ldif
echo "Saving existing data in $BACKEND"
export-ldif --backendId $BACKEND --offline --noPropertiesFile --ldifFile data/var/users.ldif

# Note: makeldif generates duplicate ou=People org entries, which causes import-ldif to abort.
# The tail -n +10 drops those first duplicates.
echo "Making $USERS  users"
( cat data/var/users.ldif & \
   makeldif -c suffix=$BASE_DN -c numusers=$USERS /var/tmp/user.template \
   | tail -n +10  )   | \
   import-ldif --clearBackend --backendId $BACKEND --offline --ldifFile /dev/stdin --noPropertiesFile --tmpDirectory data/var

echo "Rebuilding indexes"
rebuild-index --offline --noPropertiesFile --rebuildDegraded --baseDn "${BASE_DN}"

echo "You may wish to delete the data/var/users.ldif file"
