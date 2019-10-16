FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-e88c6fe9c4afe7126e2e13380d48a10d4c970c46

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
