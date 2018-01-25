#!/usr/bin/env bash
# This is the start of a script that will dynamically generate secrets, keystores, etc. for a deployment
# This has not been extensively tested - use at your own risk.

# These values need to be coordinated with the Helm charts. We need to find a good mechanism to do that.

CONFIGSTORE_PW="password"
DSAME_PW="password"

mkdir -p secrets
cd secrets

# Generate a random password.
function random() {
    openssl rand -base64 30
}

STORE_PASS=`random`
echo "Storepass is $STORE_PASS"

echo -n ${STORE_PASS} > .storepass

# Key password - keypairs are protected with this.
KEY_PASS=`random`

echo -n ${KEY_PASS} > .keypass

KEYSTORE=keystore.jceks
TYPE=jceks

rm -f ${KEYSTORE}

DN="OU=OpenAM,O=ForgeRock,L=Bristol,ST=Bristol,C=UK"

alias="rsajwtsigningkey test selfserviceenctest selfservicesigntest"

for alias in ${alias}
do
  echo "Generating cert for $alias"
  keytool -genkeypair -alias $alias -dname "CN=$alias,$DN" -keyalg RSA  -keysize 2048  \
    -sigalg SHA256WITHRSA  --validity 900 \
     -storetype ${TYPE} -keystore ${KEYSTORE} -storepass "${STORE_PASS}" -keypass "${KEY_PASS}"
done

echo "Ading sms.transport.key for Amster"
keytool -genseckey -alias sms.transport.key -keyalg AES -keysize 128 \
    -storetype ${TYPE} -keystore ${KEYSTORE} -storepass ${STORE_PASS} -keypass ${STORE_PASS}

# Do we need this? Also gen keypairs for es384test, es512test.
for alias in 256 384 521
do

  echo "Generating EC ${alias}"

   keytool -genkeypair -alias es${alias}test -dname "CN=es${alias}test,$DN"  -keyalg EC  -keysize ${alias}  \
    -sigalg SHA256withECDSA --validity 900 \
     -storetype ${TYPE} -keystore ${KEYSTORE} -storepass ${STORE_PASS} -keypass ${KEY_PASS}
done

echo "Adding configstorepwd and dsameuserpwd passwords"

echo ${CONFIGSTORE_PW} | keytool -importpass -alias  configstorepwd \
        -storetype ${TYPE} -keystore ${KEYSTORE} -storepass ${STORE_PASS} -keypass ${STORE_PASS}

echo ${DSAME_PW} | keytool -importpass -alias dsameuserpwd  \
        -storetype ${TYPE} -keystore ${KEYSTORE} -storepass ${STORE_PASS} -keypass ${STORE_PASS}

echo "done JCEKS"

KEYSTORE="keystore.jks"
TYPE="JKS"

echo "Generating legacy JKS keystore"

rm -f ${KEYSTORE}

keytool -genkeypair -alias rsajwtsigningkey -dname "CN=$rsajwtsigningkey,$DN" -keyalg RSA  -keysize 2048  \
    -sigalg SHA256WITHRSA  --validity 900 \
    -storetype ${TYPE} -keystore ${KEYSTORE} -storepass ${STORE_PASS} -keypass ${KEY_PASS}

keytool -genkeypair -alias test -dname "CN=$test,$DN" -keyalg RSA  -keysize 1024  \
    -sigalg SHA256WITHRSA  --validity 900 \
    -storetype ${TYPE} -keystore ${KEYSTORE} -storepass ${STORE_PASS} -keypass ${KEY_PASS}

echo "Generate Amster secrets"

ssh-keygen -t rsa -b 4096 -C "openam-install@example.com" -f id_rsa -q -N ""

mv id_rsa.pub authorized_keys

# If you want to tighten up the authorized_keys to an IP range- use a from option instead:
#key=`cat secrets/id_rsa.pub`
#echo "\"from=\"127.0.0.0/24,::1\" $key"   >secrets/authorized_keys
#rm secrets/id_rsa.pub
