#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-26845ee4e54462049fc15d2ee081248bd14ad09d
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-26845ee4e54462049fc15d2ee081248bd14ad09d

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
