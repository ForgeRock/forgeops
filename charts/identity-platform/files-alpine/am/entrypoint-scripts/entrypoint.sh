#!/bin/sh
# busybox ash (no bash in the alpine images); POSIX-safe form of
# files/am/entrypoint-scripts/entrypoint.sh.
# Alpine pingam variant of files/am/entrypoint-scripts/entrypoint.sh: the
# pingbase images use /home/ping (PING_HOME/FORGEROCK_HOME) instead of
# /home/forgerock, and the image's docker-entrypoint.sh lives there too.

# Base64 encode secret generate provisioned secrets if enabled
if [ -n "${SECRET_GENERATOR_AM_ENV_SECRETS}" ] ; then
    echo "updating env vars..."
    AM_AUTHENTICATION_SHARED_SECRET=$(echo $AM_AUTHENTICATION_SHARED_SECRET|base64)
    AM_SESSION_STATELESS_ENCRYPTION_KEY=$(echo $AM_SESSION_STATELESS_ENCRYPTION_KEY|base64)
    AM_SESSION_STATELESS_SIGNING_KEY=$(echo $AM_SESSION_STATELESS_SIGNING_KEY|base64)
    AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY=$(echo $AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY|base64)
fi

# Copy in the default boot.json to ensure container starts up correctly after a container restart
cp "${FORGEROCK_HOME}/openam/default-boot.json" "${FORGEROCK_HOME}/openam/config/boot.json"

# Run upstream docker-entrypoint.sh
"${FORGEROCK_HOME}/docker-entrypoint.sh"
