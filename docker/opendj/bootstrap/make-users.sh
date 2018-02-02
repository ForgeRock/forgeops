#!/usr/bin/env bash
# Sample utility to make a lot of users
cd /opt/opendj

USERS=1000000

source ./env.sh

cat <<EOF >/var/tmp/template
define suffix=$BASE_DN
define maildomain=example.com
define numusers=$USERS

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

bin/ldapmodify --continueOnError --numConnections 4 \
   -w "$PASSWORD" -D "cn=Directory Manager" --port 1389 \
   /var/tmp/l.ldif

