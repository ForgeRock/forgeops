FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-5e9e1c7a12dab93be3b81ccee374c44bac7317d8

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
