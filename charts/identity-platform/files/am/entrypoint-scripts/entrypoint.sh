#!/bin/sh
# The AM entrypoint wrapper, shared by the Debian and Alpine image lines.
# The alpine pingbase images bake FORGEROCK_HOME=/home/ping; the Debian
# images set nothing, so the default below resolves to /home/forgerock
# there. Runs via the chart's platform.amShell (sh in both modes), so the
# shebang is informational only.

# Base64 encode secret generate provisioned secrets if enabled
if [ -n "${SECRET_GENERATOR_AM_ENV_SECRETS}" ] ; then
    echo "updating env vars..."
    AM_AUTHENTICATION_SHARED_SECRET=$(echo $AM_AUTHENTICATION_SHARED_SECRET|base64)
    AM_SESSION_STATELESS_ENCRYPTION_KEY=$(echo $AM_SESSION_STATELESS_ENCRYPTION_KEY|base64)
    AM_SESSION_STATELESS_SIGNING_KEY=$(echo $AM_SESSION_STATELESS_SIGNING_KEY|base64)
    AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY=$(echo $AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY|base64)
fi

# Copy in the default boot.json to ensure container starts up correctly after a container restart
cp "${FORGEROCK_HOME:-/home/forgerock}/openam/default-boot.json" "${FORGEROCK_HOME:-/home/forgerock}/openam/config/boot.json"

# Run upstream docker-entrypoint.sh
"${FORGEROCK_HOME:-/home/forgerock}/docker-entrypoint.sh"
