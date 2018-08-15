#!/bin/sh
# args -?     3 -= sample data
. ./util.sh

prepare

set -x

echo "Setting up server..."
cd $DJ


SSL_KEYSTORE=$SECRETS/ssl-keystore.p12

./setup directory-server \
    --rootUserDn "cn=Directory Manager" \
    --rootUserPassword password \
    --monitorUserPassword password \
    --hostname "$DSHOST" \
    --adminConnectorPort ${PORT_DIGIT}444 \
    --ldapPort ${PORT_DIGIT}389 \
    --enableStartTls \
    --ldapsPort ${PORT_DIGIT}636 \
    --httpPort ${PORT_DIGIT}8080 \
    --httpsPort ${PORT_DIGIT}8443 \
    --baseDn "$BASE_DN" \
    --addBaseEntry \
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

echo "Creating IDM backend..."
./bin/dsconfig create-backend \
          --set base-dn:o=idm\
          --set enabled:true \
          --type je \
          --backend-name idmRoot \
          --offline \
          --no-prompt

# If the server is not the first, we can skip the rest of the setup, as only the first server is templated out.
if [ "${PORT_DIGIT}" != "1" ]; then
    echo "Exiting setup early for server ${PORT_DIGIT}"
    ./bin/start-ds
    exit 0
fi

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

# Prep ds for use by AM as external configuration store.
# https://backstage.forgerock.com/docs/am/6/install-guide/#prepare-configuration-store
echo "Adding ACI for configstore"
./bin/dsconfig set-access-control-handler-prop \
 --add global-aci:'(target = "ldap:///cn=schema")(targetattr = "attributeTypes ||objectClasses")(version 3.0; acl "Modify schema"; allow (write)(userdn = "ldap:///uid=openam,ou=admins,'"$BASE_DN"'");)' \
--offline \
--no-prompt


# load API schema with correct DN's (ie o=userstore vs dc=example,dc=com)
echo "Installing rest2ldap endpoint map"
cp ../../example-v1.json ./config/rest2ldap/endpoints/api

# From util.sh. Consider moving the logic here...
configure

/var/tmp/bootstrap/setup-idm.sh

#echo "Putting IDM schema extensions in place"
cp /var/tmp/schema/* ./db/schema


./bin/start-ds

# We only import the ldif on server 1 since we are going to initialize replication from it anyway.
if [ "${PORT_DIGIT}" = "1" ];
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
        bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h $DSHOST -p ${PORT_DIGIT}389 -w password /tmp/file.ldif       
    done

    # The cts files do need sed replacement - all values are hard coded to o=cts
    echo "Loading cts schema and indexes"
    for file in ../../ldif/cts/*.ldif; do
         bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h $DSHOST -p ${PORT_DIGIT}389 -w password $file
    done

    echo "Loading idm internal structure ldif"
    for file in ../../ldif/idm/*.ldif; do
         bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h $DSHOST -p ${PORT_DIGIT}389 -w password $file
    done
fi

cd ..
