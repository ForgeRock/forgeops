#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-latest-postcommit
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build@sha256:5f406320293c492c0497aec9bc72f6991630a0ab65d49996e0f551d9aeb9457f

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
