#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-310447cb2c3f39dd2f6b39ab38c14bcbe2493406
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-310447cb2c3f39dd2f6b39ab38c14bcbe2493406

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
