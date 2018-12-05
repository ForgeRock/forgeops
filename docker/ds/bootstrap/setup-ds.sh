#!/bin/sh
# args -?     3 -= sample data
. ./util.sh

prepare

set -x

echo "Setting up server..."
cd $DJ


SSL_KEYSTORE=${SECRETS}/ssl-keystore.p12

# The amCts profile with --set am-cts/tokenExpirationPolicy:ds uses the directory to reap tokens.
# Other choices are am-cts/tokenExpirationPolicy:am and am-cts/tokenExpirationPolicy:am-sessions-only
# Note this choice has some restrictions with respect to AM session notifications.
# Please refer to the documentation for futher details.

./setup directory-server \
    --rootUserDn "cn=Directory Manager" \
    --rootUserPassword password \
    --monitorUserPassword password \
    --hostname ${DSHOST} \
    --adminConnectorPort ${PORT_DIGIT}444 \
    --ldapPort ${PORT_DIGIT}389 \
    --enableStartTls \
    --ldapsPort ${PORT_DIGIT}636 \
    --httpPort ${PORT_DIGIT}8080 \
    --httpsPort ${PORT_DIGIT}8443 \
    --profile am-cts:6.5.0 \
    --set am-cts/amCtsAdminPassword:password \
    --set am-cts/tokenExpirationPolicy:ds \
    --profile am-identity-store:6.5.0 \
    --set am-identity-store/amIdentityStoreAdminPassword:password \
    --profile am-config:6.5.0 \
    --set am-config/amConfigAdminPassword:password \
    --profile idm-repo:6.5.0 \
    --certNickname ${SSL_CERT_ALIAS} \
    --usePkcs12KeyStore ${SSL_KEYSTORE} \
    --keyStorePasswordFile ${KEYSTORE_PIN} \
    --acceptLicense \
    --doNotStart


# If the server is not the first, we can skip the rest of the setup, as only the first server is templated out.
if [ "${PORT_DIGIT}" != "1" ]; then
    echo "Exiting setup early for server ${PORT_DIGIT}"
    ./bin/start-ds
    exit 0
fi

echo "Creating Default Trust Manager..."
./bin/dsconfig create-trust-manager-provider \
      --type file-based \
      --provider-name "Default Trust Manager" \
      --set enabled:true \
      --set trust-store-type:PKCS12 \
      --set trust-store-pin:\&{file:$KEYSTORE_PIN} \
      --set trust-store-file:$SSL_KEYSTORE \
      --offline \
      --no-prompt

echo "Configuring LDAP connection handler..."
./bin/dsconfig set-connection-handler-prop \
      --handler-name "LDAP" \
      --set "trust-manager-provider:Default Trust Manager" \
      --offline \
      --no-prompt

echo "Configuring LDAPS connection handler..."
./bin/dsconfig set-connection-handler-prop \
      --handler-name "LDAPS" \
      --set "trust-manager-provider:Default Trust Manager" \
      --offline \
      --no-prompt

echo "Enabling the /api endpoint"
./bin/dsconfig \
    set-http-endpoint-prop \
    --endpoint-name "/api" \
    --set enabled:true \
    --offline \
    --no-prompt


# load API schema with correct DN's (ie ou=identities)
echo "Installing rest2ldap endpoint map"
cp ../../example-v1.json ./config/rest2ldap/endpoints/api

# From util.sh. Consider moving the logic here...
configure

./bin/start-ds

cd ..
