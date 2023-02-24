#!/bin/sh
#
# Pre-setup for DS. This runs at docker build time. It creates a skeleton DS instance
# that is ready for futher customization with the runtime 'setup' script.
# After completion, a tar file is created with the contents of the setup. This tar file
# is kept as part of the docker images, and expanded at setup time to "prime" the PVC
# with the ds instance.
#
# The contents of this file are subject to the terms of the Common Development and
# Distribution License (the License). You may not use this file except in compliance with the
# License.
#
# You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
# specific language governing permission and limitations under the License.
#
# When distributing Covered Software, include this CDDL Header Notice in each file and include
# the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
# Header, with the fields enclosed by brackets [] replaced by your own identifying
# information: "Portions Copyright [year] [name of copyright owner]".
#
# Copyright 2019-2023 ForgeRock AS.
#
set -eux

rm -f template/config/tools.properties
rm -rf -- README* bat *.zip *.png *.bat setup.sh

deploymentKey=`./bin/dskeymgr create-deployment-key --deploymentKeyPassword password`

./setup --instancePath $DS_DATA_DIR \
        --serverId                docker \
        --hostname                localhost \
        --deploymentKey           ${deploymentKey} \
        --deploymentKeyPassword   password \
        --rootUserPassword        password \
        --adminConnectorPort      4444 \
        --ldapPort                1389 \
        --enableStartTls \
        --ldapsPort               1636 \
        --httpPort                8080 \
        --httpsPort               8443 \
        --replicationPort         8989 \
        --rootUserDn              uid=admin \
        --monitorUserDn           uid=monitor \
        --monitorUserPassword     password \
        --acceptLicense

./bin/dsconfig --offline --no-prompt --batch <<END_OF_COMMAND_INPUT
# Use default values for the following global settings so that it is possible to run tools when building derived images.
set-global-configuration-prop --set "server-id:&{ds.server.id|docker}"
set-global-configuration-prop --set "group-id:&{ds.group.id|default}"
set-global-configuration-prop --set "advertised-listen-address:&{ds.advertised.listen.address|localhost}"
set-global-configuration-prop --advanced --set "trust-transaction-ids:&{platform.trust.transaction.header|false}"

delete-log-publisher --publisher-name "File-Based Error Logger"
delete-log-publisher --publisher-name "File-Based Access Logger"
delete-log-publisher --publisher-name "File-Based Audit Logger "
delete-log-publisher --publisher-name "File-Based HTTP Access Logger"
delete-log-publisher --publisher-name "Json File-Based Access Logger"
delete-log-publisher --publisher-name "Json File-Based HTTP Access Logger"

create-log-publisher --type console-error --publisher-name "Console Error Logger" --set enabled:true --set default-severity:error --set default-severity:warning --set default-severity:notice --set override-severity:SYNC=INFO,ERROR,WARNING,NOTICE
create-log-publisher --type external-access --publisher-name "Console LDAP Access Logger" --set enabled:true --set config-file:config/audit-handlers/ldap-access-stdout.json --set "filtering-policy:&{ds.log.filtering.policy|inclusive}"
create-log-publisher --type external-http-access --publisher-name "Console HTTP Access Logger" --set enabled:true --set config-file:config/audit-handlers/http-access-stdout.json

delete-sasl-mechanism-handler --handler-name "GSSAPI"

set-synchronization-provider-prop --provider-name "Multimaster synchronization" --set "bootstrap-replication-server:&{ds.bootstrap.replication.servers|localhost:8989}"
# TODO: Uncomment this once we support database encryption (OPENDJ-6598).
# create-replication-domain --provider-name "Multimaster synchronization" --domain-name "cn=admin data" --set "base-dn:cn=admin data"

# Purge delay of 24 hours.
set-synchronization-provider-prop --provider-name "Multimaster synchronization" --set "replication-purge-delay:86400 s"
END_OF_COMMAND_INPUT


# These relax some settings needed by the current forgeops deployment.
dsconfig --offline --no-prompt --batch <<END_OF_COMMAND_INPUT
set-global-configuration-prop --set "unauthenticated-requests-policy:allow"

set-password-policy-prop --policy-name "Default Password Policy" \
                         --set "require-secure-authentication:false" \
                         --set "require-secure-password-changes:false" \
                         --reset "password-validator"

set-password-policy-prop --policy-name "Root Password Policy" \
                         --set "require-secure-authentication:false" \
                         --set "require-secure-password-changes:false" \
                         --reset "password-validator"
END_OF_COMMAND_INPUT


### Setup the PEM trustore. This is REQUIRED. ######

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

cd $DS_DATA_DIR

# Delete files that do not need to be peristed.
rm -fr legal-notices
rm -fr lib/extensions
ln -s /opt/opendj/lib/extensions lib/extensions

ldifmodify config/config.ldif > config/config.ldif.tmp << EOF
dn: cn=Filtering Criteria,cn=Filtered Json File-Based Access Logger,cn=Loggers,cn=config
changetype: moddn
newrdn: cn=Filtering Criteria
deleteoldrdn: 0
newsuperior: cn=Console LDAP Access Logger,cn=Loggers,cn=config

dn: cn=Filtered Json File-Based Access Logger,cn=Loggers,cn=config
changetype: delete
EOF
mv config/config.ldif.tmp config/config.ldif

# Remove the default passwords for the admin and monitor accounts.
removeUserPassword() {
    file=$1
    dn=$2

    ../bin/ldifmodify "${file}" > "${file}.tmp" << EOF
dn: ${dn}
changetype: modify
delete: userPassword
EOF
    rm "${file}"
    mv "${file}.tmp" "${file}"
}

removeUserPassword db/rootUser/rootUser.ldif "uid=admin"
removeUserPassword db/monitorUser/monitorUser.ldif "uid=monitor"

echo 'source <(/opt/opendj/bin/bash-completion)' >>~/.bashrc

# Create a tar of the data directory -used to prime the PVC
tar cvfz /opt/opendj/data.tar.gz *


# Below we enhance the bundled profiles with additional configuration for the integrated platform
cd /opt/opendj

# The profiles are read only - make them writable
chmod -R a+rw  template/setup-profiles/AM

cat ldif-ext/external-am-datastore.ldif ldif-ext/uma/*.ldif ldif-ext/alpha_bravo.ldif >> template/setup-profiles/AM/config/6.5/base-entries.ldif
cat ldif-ext/orgs.ldif >> template/setup-profiles/AM/identity-store/7.0/base-entries.ldif
