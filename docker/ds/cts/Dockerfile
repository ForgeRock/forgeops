#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-32d3e305277c101ff7349e117b5b527614e1bd69
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-32d3e305277c101ff7349e117b5b527614e1bd69

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
