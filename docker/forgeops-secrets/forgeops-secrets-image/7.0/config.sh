# Create a platform CA if one doesn't exist already

# opendj/bin/deployment-key create -f ${GEN_PATH}/ds-deployment-key/deploymentkey.key \
#                                  -w $(useRandomPass ds-deployment-key/deploymentkey.pin 24 print)

dskey_useDeploymentKey ds-deployment-key/deploymentkey.key \
                       $(useRandomPass ds-deployment-key/deploymentkey.pin 24 print)

echo "[DS] Adding master key to keystore"
# opendj/bin/deployment-key export-master-key-pair -K ${GEN_PATH}/ds/keystore \
#                                                  -W $(useRandomPass ds/keystore.pin 24 print) \
#                                                  -k $(< ${GEN_PATH}/ds-deployment-key/deploymentkey.key) \
#                                                  -w $(useRandomPass ds-deployment-key/deploymentkey.pin 24 print)

dskey_openKeyStore ds/keystore $(useRandomPass ds/keystore.pin 24 print)
dskey_wrapper export-master-key-pair -a master-key

echo "[DS] exporting platform CA from deployment key"
# mkdir -p ${GEN_PATH}/platform-ca
# opendj/bin/deployment-key export-ca-cert -f ${GEN_PATH}/platform-ca/ca.pem \
#                                          -k $(< ${GEN_PATH}/ds-deployment-key/deploymentkey.key) \
#                                          -w $(useRandomPass ds-deployment-key/deploymentkey.pin 24 print)

mkdir -p ${GEN_PATH}/platform-ca
dskey_wrapper export-ca-cert -f ${GEN_PATH}/platform-ca/ca.pem

echo "[DS] creating ssl key pair"
# opendj/bin/deployment-key create-tls-key-pair \
#                           -a ssl-key-pair \
#                           -h *.ds.default.svc.cluster.local \
#                           -h *.ds-idrepo.default.svc.cluster.local \
#                           -h *.ds-cts.default.svc.cluster.local \
#                           -h *.ds \
#                           -h *.ds-idrepo \
#                           -h *.ds-cts \
#                           -s CN=ds,O=forgerock \
#                           -K ${GEN_PATH}/ds/keystore \
#                           -W $(useRandomPass ds/keystore.pin 24 print) \
#                           -k $(< ${GEN_PATH}/ds-deployment-key/deploymentkey.key) \
#                           -w $(useRandomPass ds-deployment-key/deploymentkey.pin 24 print)

dskey_wrapper create-tls-key-pair \
              -a ssl-key-pair \
              -h *.ds.default.svc.cluster.local \
              -h *.ds-idrepo.default.svc.cluster.local \
              -h *.ds-cts.default.svc.cluster.local \
              -h *.ds \
              -h *.ds-idrepo \
              -h *.ds-cts \
              -s CN=ds,O=forgerock

dskey_closeKeyStore

echo "[DS] importing platform CA to keystore"
openKeystore "ds/keystore" \
    pkcs12 \
    $(useRandomPass ds/keystore.pin 24 print) \
    $(useRandomPass ds/keystore.pin 24 print)

keytoolgen -import -alias ca-cert \
           -trustcacerts \
           -noprompt \
           -file ${GEN_PATH}/platform-ca/ca.pem
closeKeystore


## TRUST STORE ##

echo "[TRUST STORE] Importing platform ca to trust store"

openKeystore "truststore/cacerts" \
    jks \
    changeit \
    changeit

keytoolgen -import -alias platform-ca \
           -trustcacerts \
           -noprompt \
           -file ${GEN_PATH}/platform-ca/ca.pem

closeKeystore

### DS SECRETS ###

echo "[DS] Writing DS passwords"

useRandomPass ds-passwords/monitor.pw "" "" "" "password"
useRandomPass ds-passwords/dirmanager.pw 24

# Service account passwords. These are not the directory admin password
# A job updates these passwords in LDAP

useRandomPass ds-env-secrets/AM_STORES_USER_PASSWORD 24
useRandomPass ds-env-secrets/AM_STORES_APPLICATION_PASSWORD 24
useRandomPass ds-env-secrets/AM_STORES_CTS_PASSWORD 24

## TODO: Update

# The CTS user service acccount password
# Remove
#useRandomPass ds-env-secrets/CTS_USER_SVC_PASSWORD 24


### AM SECRETS ####

echo "[AM] creating ssl keypair for https"
dskey_openKeyStore am-https/keystore.p12 $(useRandomPass am-https/keystore.pin 24 print)
dskey_wrapper create-tls-key-pair -a ssl-key-pair -h openam -s CN=am
dskey_closeKeyStore

# Secrets injected for FBC
useRandomPass am-env-secrets/AM_OIDC_CLIENT_SUBJECT_IDENTIFIER_HASH_SALT 20
useRandomPass am-env-secrets/AM_AUTHENTICATION_SHARED_SECRET 32
useRandomPass am-env-secrets/AM_SESSION_STATELESS_SIGNING_KEY 32
useRandomPass am-env-secrets/AM_SESSION_STATELESS_ENCRYPTION_KEY 32
useRandomPass am-env-secrets/AM_ENCRYPTION_KEY 32
useRandomPass am-env-secrets/AM_PASSWORDS_AMADMIN_CLEAR 24

# do we need to base64 encode this
useRandomPass am-env-secrets/AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY 32

# TODO: Do we need still need this?
useRandomPass am-env-secrets/AM_CONFIRMATION_ID_HMAC_KEY 32


# Legacy Keystore - includes boot passwords
openKeystore "am-keystore/keystore.jceks" \
    jceks \
    $(useRandomPass am-passwords/.storepass 24 print) \
    $(useRandomPass am-passwords/.keypass 24 print)

# configstore password. should not be required for FBC but AM complains if it is not in the keystore
# keytoolgen -importpass -alias configstorepwd $(useRandomPass ds-passwords/dirmanager.pw 24 print)
# keytoolgen -importpass -alias dsameuserpwd $(useRandomPass ds-passwords/dirmanager.pw 24 print)

# Note: dsameuser password doesnt really matter but it needs a place holder in the keystore.
keytoolgen -importpass -alias dsameuserpwd $(useRandomPass am-env-secrets/AM_PASSWORDS_AMADMIN_CLEAR 24 print)
keytoolgen -importpass -alias configstorepwd $(useRandomPass ds-passwords/dirmanager.pw 24 print)


genRSA rsajwtsigningkey 2048
genRSA selfserviceenctest 2048
genKey selfservicesigntest HmacSHA256 256
genEC es256test 256
genEC es384test 384
# Yes, es512test 521 is correct, see: https://backstage.forgerock.com/docs/am/6.5/authentication-guide/#configure-ecdsa-client-basedd
genEC es512test 521

genKey hmacsigningtest HMacSHA512 512
genKey directenctest aes 256

genRSA test 2048


# import SMS transport key which is the key used to encrypt the config in the forgeops-init repo.
echo "[AM Keystore] Importing SMS transport key"
keytoolgen -importkeystore \
  -destalias "sms.transport.key" \
  -srcalias "sms.transport.key" \
  -srcstoretype jceks \
  -srckeystore "sms-transport-key/sms-transport-key.jceks" \
  -srckeypass:file "sms-transport-key/keypass" \
  -srcstorepass:file "sms-transport-key/storepass"

# genKey sms.transport.key aes 128
closeKeystore



### AMSTER SECRETS ###

# Amster placeholders for OAuth clients
useRandomPass amster-env-secrets/IDM_PROVISIONING_CLIENT_SECRET 24
useRandomPass amster-env-secrets/IDM_RS_CLIENT_SECRET 24

# check to see if we already have a public key without the original name
if [ ! -f ${GEN_PATH}/amster/id_rsa.pub ] && [ -f ${GEN_PATH}/amster/authorized_keys ]; then
    cp ${GEN_PATH}/amster/authorized_keys ${GEN_PATH}/amster/id_rsa.pub
fi

# amster key for access to AM (same format as an SSH key)
genSshKey amster/id_rsa
amsterKeyCheck amster/id_rsa
cp ${GEN_PATH}/amster/id_rsa.pub ${GEN_PATH}/amster/authorized_keys

# This was need by amster during install. No longer needed?
#cp ${GEN_PATH}/amster/id_rsa.pub ${GEN_PATH}/am-boot-secrets/authorized_keys
# amster public key needed by AM. Should this be in a file?
cp ${GEN_PATH}/amster/id_rsa.pub ${GEN_PATH}/am-env-secrets/authorized_keys

### IDM Secrets ###
openKeystore "idm/keystore.jceks" \
    jceks \
    $(useRandomPass idm-env-secrets/OPENIDM_KEYSTORE_PASSWORD 24 print) \
    $(useRandomPass idm-env-secrets/OPENIDM_KEYSTORE_PASSWORD 24 print)

genKey openidm-sym-default aes 128
genKey openidm-jwtsessionhmac-key HmacSHA256 256
genKey openidm-selfservice-key aes 128

# this RSA keypair looks like it's soething to do with DJ. Get from somewhere else?
genRSA server-cert 2048
genRSA selfservice 2048
genRSA openidm-localhost 2048
cpAttr truststore/cacerts idm/truststore
closeKeystore

useRandomPass idm-env-secrets/OPENIDM_ADMIN_PASSWORD 24 noprint openidm-admin
cpAttr ds-passwords/dirmanager.pw idm-env-secrets/USERSTORE_PASSWORD
cpAttr ds-passwords/dirmanager.pw idm-env-secrets/OPENIDM_REPO_PASSWORD
cpAttr amster-env-secrets/IDM_RS_CLIENT_SECRET idm-env-secrets/RS_CLIENT_SECRET

# useRandomPass postgres-secrets/postgres-password 24
# cpAttr postgres-secrets/postgres-password idm-env-secrets/OPENIDM_REPO_PASSWORD
