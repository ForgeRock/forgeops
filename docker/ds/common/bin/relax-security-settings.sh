#!/bin/sh
set -eux

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
