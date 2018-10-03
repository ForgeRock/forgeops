#!/bin/sh
# todo: Fix me
set -x

PROXY=${1}${2}
SHARED=$PWD/shared
SSL_KEYSTORE=${PROXY}/secrets/ssl-keystore.p12
KEYSTORE_PIN=$SHARED/keystore.pin

$PROXY/bin/ldapsearch \
        --hostname ${3}${4}.example.com  \
        --port ${4}389 \
        --useStartTLS \
        --saslOption mech="EXTERNAL"  \
        --certNickName opendj-ssl \
        --keyStorePath $SSL_KEYSTORE \
        --keyStorePasswordFile $KEYSTORE_PIN \
        --trustStorePath $SSL_KEYSTORE \
        --trustStorePasswordFile $KEYSTORE_PIN \
        --baseDN dc=data \
        --searchScope base \
        "(objectClass=*)"
