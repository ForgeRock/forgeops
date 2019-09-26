# The ds-empty image configures https/https, and monitoring
#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-1fb34b6e5a823b72a9ca0b94362c7ba61a5c9176
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-1fb34b6e5a823b72a9ca0b94362c7ba61a5c9176

USER forgerock

RUN setup-profile --profile am-config \
                  --set am-config/amConfigAdminPassword:password \
 && setup-profile --profile am-identity-store \
                  --set am-identity-store/amIdentityStoreAdminPassword:password \
 && setup-profile --profile idm-repo \
                  --set idm-repo/domain:forgerock.io \
 && setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
