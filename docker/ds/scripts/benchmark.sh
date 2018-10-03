#!/usr/bin/env bash
# A sample baseline benchmark that runs against the DS user store. This modifies directory data. This should
# only be used for testing.

cd /opt/opendj

USERS="${NUMBER_SAMPLE_USERS:-1000000}"

[[ $# -eq 1 ]] && USERS=$1

ITERATIONS=1000000
BASE_DN="${BASE_DN:-dc=data}"
HOST=localhost
CONNECTIONS=10

echo "Searchrate test"
# searchrate needs more time to warm up - so we double the iterations.
ITER2=$(expr "${ITERATIONS}" \* 2 )

time bin/searchrate  -h $HOST -p 1389 -D "cn=directory manager"  -j "${DIR_MANAGER_PW_FILE}" \
    -F -c "${CONNECTIONS}" -t 4 -m "${ITER2}" -b "${BASE_DN}" -g "rand(0,$USERS)" "(uid=user.%d)"


echo  "Authrate  test"
time bin/authrate -h $HOST -p 1389 -D '%2$s'  -j "${DIR_MANAGER_PW_FILE}"  -f -c "${CONNECTIONS}"  -m $ITERATIONS  \
    -b "ou=people,$BASE_DN" -s one -g "rand(0,$USERS)" "(uid=user.%d)"

# modrate - this is destructive!
echo "Modrate test"
time bin/modrate -h $HOST -p 1389 -D "cn=directory manager" -j "${DIR_MANAGER_PW_FILE}" \
    -F -c "${CONNECTIONS}" -t 4 -m $ITERATIONS -b "uid=user.%d,ou=people,$BASE_DN" \
    -g "rand(0,$USERS)" -g "randstr(16)" 'description:%2$s'



cat >/tmp/addrate.template  <<EOF

define suffix=$BASE_DN
define maildomain=example.com

branch: [suffix]

branch: ou=People,[suffix]
subordinateTemplate: person

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
uid: test.{employeeNumber}
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

echo "addrate test (slow)"

# Reduce the number of iterations -because this test is slow!!
ITER2=$(expr "${ITERATIONS}" / 10 )
time bin/addrate -h $HOST -p 1389 -D "cn=directory manager"  -j "${DIR_MANAGER_PW_FILE}"  \
    -F -c "${CONNECTIONS}" -C random -m "${ITER2}" -s 1000 /tmp/addrate.template

