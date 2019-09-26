#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-af8f1cb83f6b279dd3613fcaf468c12886041aa2
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-af8f1cb83f6b279dd3613fcaf468c12886041aa2

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
