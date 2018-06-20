#!/bin/sh
#set -x

ARCHIVE=/var/tmp/opendj.zip
SHARED=$PWD/shared

# CA_KEYSTORE=$SHARED/ca-keystore.p12
# CA_CERT=$SHARED/ca-cert.p12
# KEYSTORE_PIN=$SHARED/keystore.pin

SSL_CERT_ALIAS=opendj-ssl
SSL_CERT_CN="CN=*.example.com,O=OpenDJ SSL"
CA_CERT_ALIAS=opendj-ca

PREFIX=${1}
PORT_DIGIT=${2}
SERVER_ID=${2}

WORKDIR=/var/tmp/ds

DJ=run/${1}${2}
#SECRETS=$DJ/secrets
SECRETS=/var/run/secrets/opendj

CA_KEYSTORE=$SECRETS/ca-keystore.p12
CA_CERT=$SECRETS/ca-cert.p12
KEYSTORE_PIN=$SECRETS/keystore.pin
SSL_KEYSTORE=$SECRETS/ssl-keystore.p12


clean()
{
    if [ -d $DJ ]; then
        $DJ/bin/stop-ds
        rm -rf $DJ
    fi
}

create_hosts()
{
    echo "127.0.0.1 dsrs1.example.com" >>/etc/hosts
    echo "127.0.0.1 dsrs2.example.com" >>/etc/hosts
}

copy_secrets()
{
    mkdir -p /var/run/secrets/opendj
    cp secrets/* /var/run/secrets/opendj
}

create_keystores()
{
    if [ -d $SECRETS ]; then 
        echo "Keystores exists - skipping"
        return
    fi

    mkdir -p $SECRETS
    cp $SHARED/* $SECRETS

    # Create SSL key pair and sign with the CA cert

    echo "password" > $KEYSTORE_PIN

    echo "Creating SSL key pair..."

    #cp $CA_CERT $SSL_KEYSTORE

    keytool -keystore $SSL_KEYSTORE \
            -storetype PKCS12 \
            -storepass:file $KEYSTORE_PIN \
            -genkeypair \
            -alias $SSL_CERT_ALIAS \
            -keyalg RSA \
            -dname "$SSL_CERT_CN" \
            -keypass:file $KEYSTORE_PIN

    keytool -keystore $SSL_KEYSTORE \
            -storetype PKCS12 \
            -storepass:file $KEYSTORE_PIN \
            -certreq \
            -alias $SSL_CERT_ALIAS | \
            \
    keytool -keystore $CA_KEYSTORE \
            -storetype PKCS12 \
            -storepass:file $KEYSTORE_PIN \
            -gencert \
            -alias $CA_CERT_ALIAS | \
            \
    keytool -keystore $SSL_KEYSTORE \
            -storetype PKCS12 \
            -storepass:file $KEYSTORE_PIN \
            -importcert \
            -alias $SSL_CERT_ALIAS
}

prepare()
{
    clean
    create_hosts
    copy_secrets
    #create_keystores 
    unzip -q $ARCHIVE
    mkdir -p run
    mv opendj $DJ
}

configure()
{
    echo "Adding system account to admin backend..."
    ADMIN_BACKEND=db/admin/admin-backend.ldif
    ADMIN_BACKEND_TMP=db/admin/admin-backend.ldif.tmp
    ./bin/ldifmodify $ADMIN_BACKEND > $ADMIN_BACKEND_TMP << EOF
dn: cn=OpenDJ,cn=Administrators,cn=admin data
changetype: add
objectClass: top
objectClass: applicationProcess
objectClass: ds-certificate-user
cn: OpenDJ
ds-certificate-subject-dn: CN=*.example.com,O=OpenDJ SSL
ds-privilege-name: config-read
ds-privilege-name: proxied-auth
EOF

    rm $ADMIN_BACKEND
    cp $ADMIN_BACKEND_TMP $ADMIN_BACKEND

    echo "Configuring Server ID..."
    ./bin/dsconfig set-global-configuration-prop \
          --set "server-id:${SERVER_ID}" \
          --offline \
          --no-prompt

    echo "Configuring Subject DN to User Attribute certificate mapper..."
    ./bin/dsconfig set-certificate-mapper-prop \
          --mapper-name "Subject DN to User Attribute" \
          --set "user-base-dn:cn=admin data" \
          --offline \
          --no-prompt

    echo "Configuring SASL/EXTERNAL mechanism handler certificate mapper..."
    ./bin/dsconfig set-sasl-mechanism-handler-prop \
          --handler-name EXTERNAL \
          --set "certificate-mapper:Subject DN to User Attribute" \
          --offline \
          --no-prompt

#    echo "Enabling LDIF audit logger..."
#    ./bin/dsconfig set-log-publisher-prop \
#          --publisher-name "File-Based Audit Logger" \
#          --set suppress-internal-operations:false \
#          --set enabled:true \
#          --offline \
#          --no-prompt

    echo "Enabling legacy LDAP access logger..."
    ./bin/dsconfig set-log-publisher-prop \
          --publisher-name "File-Based Access Logger" \
          --set enabled:true \
          --offline \
          --no-prompt

    echo "Disabling JSON LDAP access logger..."
    ./bin/dsconfig set-log-publisher-prop \
          --publisher-name "Json File-Based Access Logger" \
          --set enabled:false \
          --offline \
          --no-prompt
}
