FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-37857fd088e5717cc3b8c9675d9937a183ab80e8

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
