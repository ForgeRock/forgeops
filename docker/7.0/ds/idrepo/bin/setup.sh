#!/usr/bin/env bash
# Setup the directory server for the idrepo service.
# Add in custom tuning, index creation, etc. to this file.

# Profile and versions. If the schema for a profile has not been
# changed - it may use an older version. For example, AM 7.1 still uses the 6.5 schema for configuration
CONFIG="am-config:6.5"
AM_IDENTITY_STORE="am-identity-store:7.0"
IDM_REPO="idm-repo:7.1"
AM_CTS="am-cts:6.5"
DS_PROXIED_SERVER="ds-proxied-server:7.0"


# We also create the CTS backend for small deployments or development
# environments where a separate CTS is not warranted.
setup-profile --profile ${CONFIG} \
                  --set am-config/amConfigAdminPassword:password \
 && setup-profile --profile ${AM_IDENTITY_STORE} \
                  --set am-identity-store/amIdentityStoreAdminPassword:password \
 && setup-profile --profile ${IDM_REPO} \
                  --set idm-repo/domain:forgerock.io \
 && setup-profile --profile ${AM_CTS} \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password \
 && setup-profile --profile ${DS_PROXIED_SERVER} \
                  --set ds-proxied-server/proxyUserDn:uid=proxy \
                  --set ds-proxied-server/proxyUserCertificateSubjectDn:CN=ds,O=ForgeRock.com

# The default in 7.x is to use PBKDF2 password hashing - which is many order of magnitude slower than
# SHA-512. We recommend leaving PBKDF2 as the default as it more secure.
# If you wish to revert to the less secure SHA-512, Uncomment these lines:
#dsconfig --offline --no-prompt --batch <<EOF
##    set-password-storage-scheme-prop --scheme-name "Salted SHA-512" --set enabled:true
##    set-password-policy-prop --policy-name "Default Password Policy" --set default-password-storage-scheme:"Salted SHA-512"
#EOF


# These indexes are required for the combined AM/IDM repo
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:equality \
          --type generic \
          --index-name fr-idm-uuid
EOF

dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:extensible \
          --index-name fr-idm-managed-user-manager \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:extensible \
          --index-name fr-idm-managed-user-meta \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:extensible \
          --index-name fr-idm-managed-user-notifications \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:extensible \
          --index-name fr-idm-managed-user-roles \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:extensible \
          --index-name fr-idm-managed-user-authzroles-internal-role \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:extensible \
          --index-name fr-idm-managed-user-authzroles-managed-role \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
          --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
        --backend-name amIdentityStore \
        --set index-type:extensible \
        --index-name fr-idm-managed-organization-owner \
        --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
        --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
        --backend-name amIdentityStore \
        --set index-type:extensible \
        --index-name fr-idm-managed-organization-admin \
        --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
        --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
        --backend-name amIdentityStore \
        --set index-type:extensible \
        --index-name fr-idm-managed-organization-member \
        --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7 \
        --set index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9
EOF
# Example of creating additional indexes.
# Uncomment these as per your needs:
# dsconfig --offline --no-prompt --batch <<EOF
# create-backend-index \
#           --backend-name amIdentityStore \
#           --set index-type:equality \
#           --index-name fr-attr-i1
# EOF

# dsconfig --offline --no-prompt --batch <<EOF
# create-backend-index \
#           --backend-name amIdentityStore \
#           --set index-type:equality \
#           --index-name fr-attr-i2
# EOF


# dsconfig --offline --no-prompt --batch <<EOF
# create-backend-index \
#         --backend-name amIdentityStore \
#         --index-name fr-attr-date1 \
#         --set index-type:equality
# EOF
