#!/bin/sh
# args -?     3 -= sample data
. ./util.sh

prepare

set -x

echo "Setting up server..."
cd $DJ

SAMPLE_DATA=
if [ -n "${3}" ]; then
    SAMPLE_DATA="--sampleData ${3}"
fi

SSL_KEYSTORE=$SECRETS/ssl-keystore.p12

./setup directory-server \
    --rootUserDn "cn=Directory Manager" \
    --rootUserPassword password \
    --monitorUserPassword password \
    --hostname $DJ.example.com \
    --adminConnectorPort ${PORT_DIGIT}444 \
    --ldapPort ${PORT_DIGIT}389 \
    --enableStartTls \
    --ldapsPort ${PORT_DIGIT}636 \
    --httpPort ${PORT_DIGIT}8080 \
    --httpsPort ${PORT_DIGIT}8443 \
    ${SAMPLE_DATA} \
    --baseDn "$BASE_DN" \
    --certNickname $SSL_CERT_ALIAS \
    --usePkcs12KeyStore $SSL_KEYSTORE \
    --keyStorePasswordFile $KEYSTORE_PIN \
    --acceptLicense \
    --doNotStart

echo "Creating CTS backend..."
./bin/dsconfig create-backend \
          --set base-dn:o=cts\
          --set enabled:true \
          --type je \
          --backend-name ctsRoot \
          --offline \
          --no-prompt

cat <<EOF >/tmp/cts.ldif 
dn: o=cts
objectClass: top
objectClass: organization
o: cts
EOF

./bin/import-ldif --offline -n ctsRoot -F -l /tmp/cts.ldif


# Monitor searches will be very slow unless there is an index on uid
echo "Creating CTS UID index for uid=monitor search"
./bin/dsconfig create-backend-index \
          --backend-name ctsRoot \
          --set index-type:equality \
          --type generic \
          --index-name uid \
          --offline \
          --no-prompt


echo "Tuning the disk free space thresholds"
# For development you may want to tune the disk thresholds. TODO: Make this configurable
bin/dsconfig  set-backend-prop \
    --backend-name userRoot  \
    --set "disk-low-threshold:2GB"  --set "disk-full-threshold:1GB"  \
    --offline \
    --no-prompt

bin/dsconfig  set-backend-prop \
    --backend-name ctsRoot  \
    --set "disk-low-threshold:2GB"  --set "disk-full-threshold:1GB"  \
    --offline \
    --no-prompt


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

# From util.sh. Consider moving the logic here...
configure

./bin/start-ds

IMPORT_LDIF=yes
# Do we only need to do this on server 1?
if [ "$IMPORT_LDIF" ];
then
    export DB_NAME=userRoot
    # Import LDIF
    for file in ../../ldif/userstore/*.ldif; do
        echo "Loading $file"
        # search + replace all placeholder variables. Naming conventions are from AM.
        sed -e "s/@BASE_DN@/$BASE_DN/"  \
            -e "s/@userStoreRootSuffix@/$BASE_DN/"  \
            -e "s/@DB_NAME@/$DB_NAME/"  \
            -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/"  <${file}  >/tmp/file.ldif
        #cat /tmp/file.ldif
        bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -w password /tmp/file.ldif       
    done

    # The cts files do need sed replacement - all values are hard coded to o=cts
    echo "Loading cts schema and indexes"
    bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -w password ../../ldif/cts/*
fi

cd ..
