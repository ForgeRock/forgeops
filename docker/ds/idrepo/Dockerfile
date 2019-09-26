# The ds-empty image configures https/https, and monitoring
#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-310447cb2c3f39dd2f6b39ab38c14bcbe2493406
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-310447cb2c3f39dd2f6b39ab38c14bcbe2493406

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
