#!/bin/sh

SERVER=${1}${2}
SHARED=$PWD/shared
SSL_KEYSTORE=${SERVER}/secrets/ssl-keystore.p12
KEYSTORE_PIN=$SHARED/keystore.pin

./run/$SERVER/bin/ldapmodify \
        --hostname $SERVER.example.com  \
        --port ${2}389 \
        --useStartTLS \
        -D "cn=directory manager" \
        -w password \
        -X \
        --postReadAttributes "description" << EOF
dn: uid=user.0,ou=people,o=userstore
changetype: modify
replace: description
description: `date`
EOF
