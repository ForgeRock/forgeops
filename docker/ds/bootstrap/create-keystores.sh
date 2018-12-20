#!/bin/sh
# Create sample keystores
# TODO: Note this is currently failng to sign the SSL certifcate. We are using Key Tool explorer to sign the cert

SSL_CERT_ALIAS=opendj-ssl
SSL_CERT_CN="CN=*.example.com,O=OpenDJ SSL"
CA_CERT_ALIAS=opendj-ca

SECRETS=./secrets
CA_KEYSTORE=$SECRETS/ca-keystore.p12
CA_CERT=$SECRETS/ca-cert.p12
KEYSTORE_PIN=$SECRETS/keystore.pin
SSL_KEYSTORE=$SECRETS/ssl-keystore.p12

set -x 

rm -fr $SECRETS
mkdir -p $SECRETS

echo "password" >$KEYSTORE_PIN

create_keystores()
{
    # if [ -d $SECRETS ]; then 
    #     echo "Keystores exists - skipping"

    #     return
    # fi

    # Create SSL key pair and sign with the CA cert
    echo "Creating SSL key pair..."

    #  keytool -keystore $CA_KEYSTORE \
    #         -storetype PKCS12 \
    #         -storepass:file $KEYSTORE_PIN \
    #         -genkeypair \
    #         -alias $CA_CERT_ALIAS \
    #         -keyalg RSA \
    #         -dname "$SSL_CERT_CN" \
    #         -keypass:file $KEYSTORE_PIN

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

create_ca()
{
    # Create a self signed key pair root CA certificate.
    keytool -genkeypair -v \
    -alias $CA_CERT_ALIAS \
    -dname "O=OpenDJ CA" \
    -keystore $CA_KEYSTORE \
    -keypass:file $KEYSTORE_PIN \
    -storetype PKCS12 \
    -storepass:file $KEYSTORE_PIN \
    -keyalg RSA \
    -keysize 4096 \
    -ext KeyUsage="keyCertSign" \
    -ext BasicConstraints:"critical=ca:true" \
    -validity 9999

    # Export the exampleCA public certificate so that it can be used in trust stores..
    # keytool -export -v \
    # -alias $CA_CERT_ALIAS \
    # -file exampleca.crt \
    # -keypass:file $KEYSTORE_PIN \
    # -storepass:file $KEYSTORE_PIN \
    # -keystore $CA_KEYSTORE \
    # -storetype PKCS12 \
    # -rfc
}

create_ca
create_keystores