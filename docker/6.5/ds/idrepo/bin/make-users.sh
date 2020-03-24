#!/usr/bin/env bash
# Sample utility to make a lot of bulk users.
# Usage:  make-users.sh number-users [uid-start-number]
cd /opt/opendj


# Default users
USERS=10000000
BASE_DN="ou=identities"
START=0
BASE_DN="ou=identities"
BACKEND=amIdentityStore
PW_FILE="${DIR_MANAGER_PW_FILE:-/var/tmp/.passwd}"
if [ ! -r ${PW_FILE} ] 
then
	#echo "No file found...read it from ENV ADMIN_PASSWORD"
    echo -n "$ADMIN_PASSWORD" > "/var/tmp/.passwd"
fi


# TODO: Is there a need to start at non zero?
[[ $# -eq 1 ]] && USERS=$1
[[ $# -eq 2 ]] && USERS=$1 && START=$2

# The value below is "password" encoded with PBKDF2. Note '{' chars are escaped
# \{PBKDF2-HMAC-SHA256\}10000:xKsMmlzVLRYdYzcgBuD3ZIAeSj8tNhjDHGFDqhth8Kcbw5qjL5UZxaiS2awL1HjO
# Same value encoded with SSHA-512
# \{SSHA512\}YFIBSgo+6316zKQ1/FY2ij2Dgt3X7UHBMaeUVb6UDUOOm7HnT0gn/6s9vo44bdspuh6RE2k5a4D71+VX9xVgI1W3bfWbUrZi9rgkGOGRxiE=
# The template below is the same as config/MakeLDIF/example.template, execpt the userPassword is pre-encoded using
# one of the values above. Pre-encoding will save considerable time during import. If you want to change the
# scheme, update the userPassword: field with one of these pre-encoded values.
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
userPassword: \{SSHA512\}YFIBSgo+6316zKQ1/FY2ij2Dgt3X7UHBMaeUVb6UDUOOm7HnT0gn/6s9vo44bdspuh6RE2k5a4D71+VX9xVgI1W3bfWbUrZi9rgkGOGRxiE=
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


# Note the memory allocated here can not exceed the pod memory limit -
# which includes the command below AND the ds server itself.
# You may have to tune this value
#export OPENDJ_JAVA_ARGS="${OPENDJ_JAVA_ARGS:--XX:MaxRAMPercentage=10.0}"
export OPENDJ_JAVA_ARGS="-XX:MaxRAMPercentage=10.0"


# In order to preserve the backend, we need to export the existing entries
# If you dont do this the backend will not start.
mkdir -p data/var
rm -f data/var/users.ldif
echo "Saving existing data in $BACKEND"
export-ldif --backendId $BACKEND  --bindDN "cn=Directory Manager" --bindPasswordFile "${PW_FILE}"  \
 --port 4444 --trustAll \
 --noPropertiesFile --ldifFile data/var/users.ldif


# Note: makeldif generates duplicate ou=People org entries, which causes import-ldif to abort.
# The tail -n +10 drops those first duplicates. Yes this is a hack.
echo "Making $USERS  users"

( cat data/var/users.ldif & \
   makeldif -c suffix=$BASE_DN -c numusers=$USERS /var/tmp/user.template \
   | tail -n +10  )  >data/var/import.ldif


import-ldif --clearBackend --backendId $BACKEND --ldifFile data/var/import.ldif \
   --skipFile /tmp/skip  --rejectFile /tmp/rejects \
   --noPropertiesFile --port 4444 --trustAll \
   --bindDN "cn=Directory Manager" --bindPasswordFile "${PW_FILE}" --clearBackend --overwrite
