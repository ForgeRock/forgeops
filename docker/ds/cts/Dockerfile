#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-1fb34b6e5a823b72a9ca0b94362c7ba61a5c9176
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-1fb34b6e5a823b72a9ca0b94362c7ba61a5c9176

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
