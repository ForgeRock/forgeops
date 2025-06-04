#!/usr/bin/env bash

# Base64 encode secret generate provisioned secrets if enabled
if [ -n "${SECRET_GENERATOR_AM_ENV_SECRETS}" ] ; then
    echo "updating env vars..."
    AM_AUTHENTICATION_SHARED_SECRET=$(echo $AM_AUTHENTICATION_SHARED_SECRET|base64)
    AM_SESSION_STATELESS_ENCRYPTION_KEY=$(echo $AM_SESSION_STATELESS_ENCRYPTION_KEY|base64)
    AM_SESSION_STATELESS_SIGNING_KEY=$(echo $AM_SESSION_STATELESS_SIGNING_KEY|base64)
    AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY=$(echo $AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY|base64)
fi

# Copy in the default boot.json to ensure container starts up correctly after a container restart
cp /home/forgerock/openam/default-boot.json /home/forgerock/openam/config/boot.json

# Run upstream docker-entrypoint.sh
/home/forgerock/docker-entrypoint.sh

