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

### AM SECRETS ####

echo "[AM] creating ssl keypair for https"
dskey_openKeyStore am-https/keystore.p12 $(useRandomPass am-https/keystore.pin 24 print)
dskey_wrapper create-tls-key-pair -a ssl-key-pair -h openam -s CN=am
dskey_closeKeyStore

# keystore for AM containing boot secrets
openKeystore "am-boot-secrets/keystore.jceks" \
    jceks \
    $(useRandomPass am-boot-secrets/.storepass 24 print) \
    $(useRandomPass am-boot-secrets/.keypass 24 print)

keytoolgen -importpass -alias dsameuserpwd $(useRandomPass amster-env-secrets/AMADMIN_PASS 24 print) 
keytoolgen -importpass -alias configstorepwd $(useRandomPass ds-passwords/dirmanager.pw 24 print)

# DS password used in boot.sh to check to see if AM is configured
cpAttr ds-passwords/dirmanager.pw am-env-secrets/CFGDIR_PASS

genRSA test 2048
genRSA rsajwtsigningkey 2048

# import SMS transport key which is the key used to encrypt the config in the forgeops-init repo.
echo "[AM Keystore] Importing SMS transport key"
keytoolgen -importkeystore \
  -destalias "sms.transport.key" \
  -srcalias "sms.transport.key" \
  -srcstoretype jceks \
  -srckeystore "sms-transport-key/sms-transport-key.jceks" \
  -srckeypass:file "sms-transport-key/keypass" \
  -srcstorepass:file "sms-transport-key/storepass"

closeKeystore

openKeystore "am-runtime-keystore/keystore-runtime.jceks" \
    jceks \
    $(useRandomPass am-runtime-passwords/storepassruntime 24 print) \
    $(useRandomPass am-runtime-passwords/keypassruntime 24 print)
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
genRSA rsajwtsigningkey 2048

# genKey sms.transport.key aes 128
closeKeystore

### AMSTER SECRETS ###

cpAttr ds-passwords/dirmanager.pw amster-env-secrets/CFGDIR_PASS
cpAttr ds-passwords/dirmanager.pw amster-env-secrets/USRDIR_PASS
cpAttr ds-passwords/dirmanager.pw amster-env-secrets/CTSDIR_PASS

useRandomPass amster-env-secrets/AMADMIN_PASS 24
useRandomPass amster-env-secrets/AM_ENC_KEY 32
useRandomPass amster-env-secrets/AM_POLICY_AGENT_PASS 24

useRandomPass amster-env-secrets/CTSUSR_PASS 24
useRandomPass amster-env-secrets/CFGUSR_PASS 24
useRandomPass amster-env-secrets/USRUSR_PASS 24

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
cp ${GEN_PATH}/amster/id_rsa.pub ${GEN_PATH}/am-boot-secrets/authorized_keys


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
