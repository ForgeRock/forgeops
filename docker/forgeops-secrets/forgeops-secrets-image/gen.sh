#!/bin/bash
set -euo pipefail

STA_PATH="static"
SMS_PATH="am-sms/sms_transport_keystore.jceks"
DN="O=ForgeRock,L=Bristol,ST=Bristol,C=UK"
DS_SANS="DNS:opendj,DNS:localhost,DNS:ds-cts-0.ds-cts,DNS:ds-cts-1.ds-cts,DNS:ds-idrepo-0.id-repo,DNS:ds-idrepo-1.id-repo"
KS_CHANGED=0
VALIDITY=3650
TEMP_PATH="./temp"
KEYTOOL_STDERR_FILTER="Warning:\|keystore uses a proprietary format. It is recommended to migrate"

source gen-functions.sh
source config/version.sh
source ${CONFIG_VERSION}/config.sh

echo "Secrets generation complete. $(find ${GEN_PATH} -type f | wc -l) files in generated folder."
