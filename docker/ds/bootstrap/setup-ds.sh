#!/bin/sh
# args -?     3 -= sample data
. ./util.sh

prepare

set -x

echo "Setting up server..."
cd $DJ


SSL_KEYSTORE=${SECRETS}/ssl-keystore.p12


EXTRA_OPTS=""

# Note the REAPER_TYPE variable is set by ENV in the Dockerfile
if [ "${REAPER_TYPE}" = "TTL" ]
then
   EXTRA_OPTS="--set am-cts/useAmReaper:false --set am-cts/ttlAttribute:coreTokenExpirationDate"
fi

if [ "${REAPER_TYPE}" = "HYBRID" ]
then
   EXTRA_OPTS="--set am-cts/useAmReaper:false --set am-cts/ttlAttribute:coreTokenTtlDate"
fi

echo "EXTRA_OPTS=${EXTRA_OPTS}"

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
    --set domain:data \
    --profile am-cts:6.5.0 \
    --set am-cts/amCtsAdminPassword:password \
    --profile am-identity-store \
    --set am-identity-store/amIdentityStoreAdminPassword:password \
    --certNickname ${SSL_CERT_ALIAS} \
    --usePkcs12KeyStore ${SSL_KEYSTORE} \
    --keyStorePasswordFile ${KEYSTORE_PIN} \
    --acceptLicense \
    --doNotStart ${EXTRA_OPTS}


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


# load API schema with correct DN's (ie dc=data)
echo "Installing rest2ldap endpoint map"
cp ../../example-v1.json ./config/rest2ldap/endpoints/api

# From util.sh. Consider moving the logic here...
configure

echo "Copy schema extensions in place. Only AM config schema is copied."
cp /var/tmp/schema/* ./db/schema


./bin/start-ds

# We only import the ldif on server 1 since we are going to initialize replication from it anyway.
if [ "${PORT_DIGIT}" = "1" ];
then
    # TODO: Only for userstore (amIdentityStore) while OpenDJ-5531 is resolved.
    for file in ../../ldif/userstore/*.ldif; do
        echo "Loading ${file}"
        # search + replace all placeholder variables. Naming conventions are from AM.
        sed -e "s/@BASE_DN@/$BASE_DN/"  <${file}  >/tmp/file.ldif
        bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h ${DSHOST} -p ${PORT_DIGIT}389 -w password /tmp/file.ldif
    done
fi

cd ..
