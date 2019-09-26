#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-f4b3f461130bad766b730503fd2b1c357354acb3
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-f4b3f461130bad766b730503fd2b1c357354acb3

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
