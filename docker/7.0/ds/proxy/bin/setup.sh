#!/usr/bin/env bash
# Setup the directory server for the idrepo service.
# Add in custom tuning, index creation, etc. to this file.

version=$1
DS_PROXY_SERVER="ds-proxy-server"
DS_PROXY_SERVER_SCHEMA="ds-proxy-server-schema"

setup-profile --profile ${DS_PROXY_SERVER} \
                  --set ds-proxy-server/backendName:proxyRoot \
                  --set ds-proxy-server/bootstrapReplicationServer:"&{dsproxy.bootstrap.replication.servers}" \
                  --set ds-proxy-server/rsConnectionSecurity:start-tls \
                  --set ds-proxy-server/keyManagerProvider:PKCS12 \
                  --set ds-proxy-server/trustManagerProvider:PKCS12 \
                  --set ds-proxy-server/certNickname:ssl-key-pair \
                  --set ds-proxy-server/primaryGroupId:"&{dsproxy.primary.group.id|default}" 
                #   --set ds-proxy-server/baseDn:dc=openidm,dc=forgerock,dc=io

setup-profile --profile ${DS_PROXY_SERVER_SCHEMA} 

dsconfig --offline --no-prompt \
create-global-access-control-policy \
            --policy-name "Authenticated access to forgerock.io data" \
            --set authentication-required:true \
            --set permission:read \
            --set permission:write \
            --set allowed-attribute:"*" \
            --set allowed-attribute:"+" \
            --set allowed-attribute-exception:authPassword \
            --set allowed-attribute-exception:userPassword

dsconfig --offline --no-prompt \
create-global-access-control-policy \
            --policy-name "Allow persistent search" \
            --set authentication-required:true \
            --set user-dn-equal-to:"uid=am-identity-bind-account,ou=admins,ou=identities" \
            --set user-dn-equal-to:"uid=am-config,ou=admins,ou=am-config" \
            --set user-dn-equal-to:"uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens" \
            --set allowed-control:2.16.840.1.113730.3.4.3

# TODO: Need a better way to import schema from setup profiles or directly from backend servers
cp /opt/opendj/template/setup-profiles/AM/config/6.5/schema/* /opt/opendj/config/schema/
cp /opt/opendj/template/setup-profiles/IDM/repo/7.1/schema/* /opt/opendj/config/schema/
cp /opt/opendj/template/setup-profiles/AM/identity-store/7.0/schema/* /opt/opendj/config/schema/
cp /opt/opendj/template/setup-profiles/AM/cts/6.5/schema/* /opt/opendj/config/schema/
