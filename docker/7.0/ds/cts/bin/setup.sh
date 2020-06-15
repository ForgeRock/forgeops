#!/usr/bin/env bash
# Setup the directory server for the idrepo service.
# Add in custom tuning, index creation, etc. to this file.

version=$1

AM_CTS="am-cts"

# Select DS profile version
if [[ ! -z $version ]]; then 
    AM_CTS="${AM_CTS}:${version}"
fi

setup-profile --profile ${AM_CTS} \
              --set am-cts/tokenExpirationPolicy:ds \
              --set am-cts/amCtsAdminPassword:password

# The default in 7.x is to use PBKDF2 password hashing - which is many order of magnitude slower than
# SHA-512. We recommend leaving PBKDF2 as the default as it more secure.
# If you wish to revert to the less secure SHA-512, Uncomment these lines:
#dsconfig --offline --no-prompt --batch <<EOF
##    set-password-storage-scheme-prop --scheme-name "Salted SHA-512" --set enabled:true
##    set-password-policy-prop --policy-name "Default Password Policy" --set default-password-storage-scheme:"Salted SHA-512"
#EOF
