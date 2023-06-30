#!/usr/bin/env bash
set -e
# Setup the directory server for the idrepo service.
# Add in custom tuning, index creation, etc. to this file.

# The CTS and proxy schemas have not changed for 7.x
AM_CTS="am-cts:6.5"
DS_PROXIED_SERVER="ds-proxied-server:7.0"
PEM_KEYS_DIRECTORY="pem-keys-directory"
PEM_TRUSTSTORE_DIRECTORY="pem-trust-directory"

setup-profile --profile ${AM_CTS} \
              --set am-cts/tokenExpirationPolicy:am-sessions-only \
              --set am-cts/amCtsAdminPassword:password \
&& setup-profile --profile ${DS_PROXIED_SERVER} \
                  --set ds-proxied-server/proxyUserDn:uid=proxy \
                  --set ds-proxied-server/proxyUserCertificateSubjectDn:CN=ds,O=ForgeRock.com

# Reduce changelog purge interval to 12 hours
dsconfig set-synchronization-provider-prop \
          --provider-name Multimaster\ Synchronization \
          --set replication-purge-delay:43200\ s \
          --no-prompt \
          --offline

# The default in 7.x is to use PBKDF2 password hashing - which is many order of magnitude slower than
# SHA-512. We recommend leaving PBKDF2 as the default as it more secure.
# If you wish to revert to the less secure SHA-512, Uncomment these lines:
#dsconfig --offline --no-prompt --batch <<EOF
##    set-password-storage-scheme-prop --scheme-name "Salted SHA-512" --set enabled:true
##    set-password-policy-prop --policy-name "Default Password Policy" --set default-password-storage-scheme:"Salted SHA-512"
#EOF

mkdir -p $PEM_TRUSTSTORE_DIRECTORY
mkdir -p $PEM_KEYS_DIRECTORY

# Set up a PEM Trust Manager Provider
dsconfig --offline --no-prompt --batch <<EOF
create-trust-manager-provider \
            --provider-name "PEM Trust Manager" \
            --type pem \
            --set enabled:true \
            --set pem-directory:${PEM_TRUSTSTORE_DIRECTORY}

set-connection-handler-prop \
            --handler-name https \
            --set trust-manager-provider:"PEM Trust Manager"
set-connection-handler-prop \
            --handler-name ldap \
            --set trust-manager-provider:"PEM Trust Manager"
set-connection-handler-prop \
            --handler-name ldaps \
            --set trust-manager-provider:"PEM Trust Manager"
set-synchronization-provider-prop \
            --provider-name "Multimaster Synchronization" \
            --set trust-manager-provider:"PEM Trust Manager"
set-administration-connector-prop \
            --set trust-manager-provider:"PEM Trust Manager"

# Delete the default PCKS12 provider.
delete-trust-manager-provider \
            --provider-name "PKCS12"

# Set up a PEM Key Manager Provider
create-key-manager-provider \
            --provider-name "PEM Key Manager" \
            --type pem \
            --set enabled:true \
            --set pem-directory:${PEM_KEYS_DIRECTORY}

set-connection-handler-prop \
            --handler-name https \
            --set key-manager-provider:"PEM Key Manager"
set-connection-handler-prop \
            --handler-name ldap \
            --set key-manager-provider:"PEM Key Manager"
set-connection-handler-prop \
            --handler-name ldaps \
            --set key-manager-provider:"PEM Key Manager"
set-synchronization-provider-prop \
            --provider-name "Multimaster Synchronization" \
            --set key-manager-provider:"PEM Key Manager"
set-crypto-manager-prop \
            --set key-manager-provider:"PEM Key Manager"
set-administration-connector-prop \
            --set key-manager-provider:"PEM Key Manager"

# Delete the default PCKS12 provider.
delete-key-manager-provider \
            --provider-name "PKCS12"
EOF
