#!/bin/sh
#
# Pre-setup for DS. This runs at docker build time. It creates a skeleton DS
# instance that is ready for further customization with the runtime 'setup'
# script. After completion, a tar file is created with the contents of the
# setup. This tar file is kept as part of the docker image, and expanded at
# setup time to "prime" the PVC with the ds instance.
#
# Single-image build (no build-time mode): bakes ONE skeleton, always in the
# forgeops layout, including all of the platform extensions that used to be
# forgeops-mode-only: relaxed password policies, allow-multiple-password-
# values for no-downtime rotation, PEM Trust/Key Manager providers
# (replacing PKCS12), data.tar.gz priming of the PVC, ldif-ext enhancements
# to the AM/IDM setup profiles, and the custom-schema layout consumed by the
# runtime setup scripts.
#
# IMAGE_MODE is a RUNTIME selector only (see docker-entrypoint.sh): it picks
# the runtime contract (base = upstream samples/docker behavior against this
# same baked instance, forgeops = the k8s/PVC contract), never what gets
# baked. The historical base/forgeops bake split is gone.
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
# Copyright 2019-2025 Ping Identity Corporation.
#
set -eux

# busybox ash: no arrays; keep the base DNs as a newline-joined variable.
# Alpine busybox tar has no --no-overwrite-dir; plain tar is fine because
# extraction happens into an empty DS_DATA_DIR.

# Single-image build (no build-time mode): ONE baked skeleton, always in the
# forgeops layout - setup runs with --instancePath $DS_DATA_DIR (instance.loc
# points there) so everything persistable lives under the PVC mount point,
# data.tar.gz primes a fresh PVC, and the platform extensions below are part
# of the skeleton. IMAGE_MODE is a RUNTIME selector only (see
# docker-entrypoint.sh): it picks the runtime contract (base = upstream
# samples/docker behavior against this same baked instance, forgeops = the
# k8s/PVC contract), not what gets baked.
MODE=${IMAGE_MODE:-base}
case "$MODE" in
    base|forgeops) ;;
    *) echo "ds-setup.sh: unknown IMAGE_MODE '$MODE' (expected base or forgeops)" >&2; exit 1 ;;
esac

# The instance root is always $DS_DATA_DIR (PVC-persisted layout;
# instance.loc points there). Raw file operations below (ldifmodify on
# config/db files) address the instance via this variable; DS tools
# (dsconfig/ldifmodify wrappers) resolve the same root themselves via
# instance.loc.
INSTANCE_DIR="$DS_DATA_DIR"

rm -f template/config/tools.properties

# Upstream setup.sh copies samples/docker/* into the server root before
# running ./setup - that is what brings template/config/audit-handlers (and
# the docker-entrypoint.sh/logger.sh of the upstream layout) into place.
# This image ships its own entrypoint/env.sh instead of upstream's, so only
# the template subtree is mirrored here.
cp -r samples/docker/template .

# The upstream archive assembles template/ subdirectories with directoryMode
# 744 (owner-only traverse). Servers/other tools running as a different uid
# (e.g. a k8s pod with runAsUser 11111) cannot descend into them, which makes
# the runtime "upgrade" tool fail with "'template/db/schema/xx.ldif' is
# missing or empty, it is probably corrupted". Re-add group/other rx.
chmod -R a+rX template

rm -rf -- README* bat *.zip *.png *.bat setup.sh

deploymentId=$(./bin/dskeymgr create-deployment-id --deploymentIdPassword password)

# setup --instancePath $DS_DATA_DIR creates instance.loc -> data, so the
# instance root is /opt/opendj/data: the ForgeOps k8s contract, where
# everything under $DS_DATA_DIR is PVC-persisted. Always baked this way in
# the single-image build.
./setup --instancePath "$DS_DATA_DIR" \
        --serverId                docker \
        --hostname                localhost \
        --deploymentId            ${deploymentId} \
        --deploymentIdPassword    password \
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

create-log-publisher --type console-error --publisher-name "Console Error Logger" --set enabled:true --set json-output:true --set default-severity:notice --set override-severity:SYNC=INFO
create-log-publisher --type external-access --publisher-name "Console LDAP Access Logger" --set enabled:true --set config-file:config/audit-handlers/ldap-access-stdout.json --set "filtering-policy:&{ds.log.filtering.policy|inclusive}"
create-log-publisher --type external-http-access --publisher-name "Console HTTP Access Logger" --set enabled:true --set config-file:config/audit-handlers/http-access-stdout.json

delete-sasl-mechanism-handler --handler-name "GSSAPI"

set-synchronization-provider-prop --provider-name "Multimaster synchronization" --set "bootstrap-replication-server:&{ds.bootstrap.replication.servers|localhost:8989}"
# TODO: Uncomment this once we support database encryption (OPENDJ-6598).
# create-replication-domain --provider-name "Multimaster synchronization" --domain-name "cn=admin data" --set "base-dn:cn=admin data"
# TODO: Uncomment this once we support optional schema replication.
# create-replication-domain --provider-name "Multimaster synchronization" --domain-name "cn=schema" --set "base-dn:cn=schema" --set "enabled:&{ds.enable.schema.replication|false}"
delete-replication-domain --provider-name "Multimaster synchronization" --domain-name "cn=schema"
END_OF_COMMAND_INPUT

./bin/ldifmodify "$INSTANCE_DIR/config/config.ldif" > "$INSTANCE_DIR/config/config.ldif.tmp" << EOF
dn: cn=Filtering Criteria,cn=Filtered Json File-Based Access Logger,cn=Loggers,cn=config
changetype: moddn
newrdn: cn=Filtering Criteria
deleteoldrdn: 0
newsuperior: cn=Console LDAP Access Logger,cn=Loggers,cn=config

dn: cn=Filtered Json File-Based Access Logger,cn=Loggers,cn=config
changetype: delete
EOF
rm "$INSTANCE_DIR/config/config.ldif"
mv "$INSTANCE_DIR/config/config.ldif.tmp" "$INSTANCE_DIR/config/config.ldif"


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

# Purge delay of 24 hours.
set-synchronization-provider-prop --provider-name "Multimaster synchronization" --set "replication-purge-delay:86400 s"

# Allow multiple passwords for no downtime rotations
set-password-policy-prop --policy-name "Default Password Policy" --set allow-multiple-password-values:true
set-password-policy-prop --policy-name "Root Password Policy" --set allow-multiple-password-values:true
END_OF_COMMAND_INPUT

### Setup the PEM truststore. This is REQUIRED. ######

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

# Delete the default PKCS12 provider.
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

# Delete the default PKCS12 provider.
delete-key-manager-provider \
        --provider-name "PKCS12"
EOF

# Set the crypto manager to the PEM key manager in config.ldif as well.
ldifmodify "$INSTANCE_DIR/config/config.ldif" > "$INSTANCE_DIR/config/config.ldif.tmp" << EOF
dn: cn=Crypto Manager,cn=config
changetype: modify
replace: ds-cfg-key-manager-provider
ds-cfg-key-manager-provider: cn=PEM Key Manager,cn=Key Manager Providers,cn=config
EOF
rm "$INSTANCE_DIR/config/config.ldif"
mv "$INSTANCE_DIR/config/config.ldif.tmp" "$INSTANCE_DIR/config/config.ldif"

# Remove the default passwords for the admin and monitor accounts.
removeUserPassword() {
    file=$1
    dn=$2

    ./bin/ldifmodify "${file}" > "${file}.tmp" << EOF
dn: ${dn}
changetype: modify
delete: userPassword
EOF
    rm "${file}"
    mv "${file}.tmp" "${file}"
}

removeUserPassword "$INSTANCE_DIR/db/rootUser/rootUser.ldif" "uid=admin"
removeUserPassword "$INSTANCE_DIR/db/monitorUser/monitorUser.ldif" "uid=monitor"

# Create a tar of the instance - used to prime the PVC. In forgeops mode
# the instance root IS $DS_DATA_DIR (setup ran with --instancePath), so
# tarring it directly captures the full persistable state (db/, config/,
# changelogDb/, ...) in the layout the runtime entrypoint expects when it
# extracts this tar into a fresh PVC.
tar cvfz /opt/opendj/data.tar.gz -C "$DS_DATA_DIR" .

# Below we enhance the bundled profiles with additional configuration for
# the integrated platform.
cd /opt/opendj

# The profiles are read only - make them writable
chmod -R a+rw template/setup-profiles/AM
chmod -R a+rw template/setup-profiles/IDM

# Add custom ldap entries to the am-config base entries
cat ldif-ext/am-config/uma/*.ldif ldif-ext/am-config/*.ldif >> template/setup-profiles/AM/config/6.5/base-entries.ldif

# Add custom ldap entries to the identity-store base entries
if [ -f ldif-ext/identities/*.ldif ]; then
    cat ldif-ext/identities/*.ldif >> template/setup-profiles/AM/identity-store/7.0/base-entries.ldif
fi

# Add custom ldap entries to the tokens base entries
if [ -f ldif-ext/tokens/*.ldif ]; then
    cat ldif-ext/tokens/*.ldif >> template/setup-profiles/AM/cts/6.5/base-entries.ldif
fi

# Add custom ldap entries to the idm-repo base entries
if [ -f ldif-ext/idm-repo/*.ldif ]; then
    cat ldif-ext/idm-repo/*.ldif >> template/setup-profiles/IDM/repo/7.3/base-entries.ldif
fi

# add mtls objectclass to bind accounts in template ldifs (note the difference in case between templates)
sed -i '/objectClass: inetOrgPerson/aobjectClass: ds-certificate-user' template/setup-profiles/AM/cts/6.5/base-entries.ldif
sed -i '/objectClass: inetOrgPerson/aobjectClass: ds-certificate-user' template/setup-profiles/AM/identity-store/7.0/base-entries.ldif
sed -i '/objectclass: inetOrgPerson/aobjectClass: ds-certificate-user' template/setup-profiles/AM/config/6.5/base-entries.ldif

echo 'source <(/opt/opendj/bin/bash-completion)' >> ~/.bashrc
