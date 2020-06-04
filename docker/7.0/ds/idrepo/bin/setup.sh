#!/usr/bin/env bash
# Setup the directory server for the idrepo service.
# Add in custom tuning, index creation, etc. to this file.

version=$1

CONFIG="am-config"
AM_IDENTITY_STORE="am-identity-store"
IDM_REPO="idm-repo"
AM_CTS="am-cts"

# Select DS profile version
if [[ ! -z $profile ]]; then 
    CONFIG="${CONFIG}:${version}"
    AM_IDENTITY_STORE="${AM_IDENTITY_STORE}:${version}"
    IDM_REPO="${IDM_REPO}:${version}"
    AM_CTS="${AM_CTS}:${version}"
fi

setup-profile --profile ${CONFIG} \
                  --set am-config/amConfigAdminPassword:password \
 && setup-profile --profile ${AM_IDENTITY_STORE} \
                  --set am-identity-store/amIdentityStoreAdminPassword:password \
 && setup-profile --profile ${IDM_REPO} \
                  --set idm-repo/domain:forgerock.io \
 && setup-profile --profile ${AM_CTS} \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

# The default in 7.x is to use PBKDF2 password hashing - which is many order of magnitude slower than
# SHA-512. We recommend leaving PBKDF2 as the default as it more secure.
# If you wish to revert to the less secure SHA-512, Uncomment these lines:
#dsconfig --offline --no-prompt --batch <<EOF
##    set-password-storage-scheme-prop --scheme-name "Salted SHA-512" --set enabled:true
##    set-password-policy-prop --policy-name "Default Password Policy" --set default-password-storage-scheme:"Salted SHA-512"
#EOF
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:equality \
          --type generic \
          --index-name fr-idm-uuid
EOF

