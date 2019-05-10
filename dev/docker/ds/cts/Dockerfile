FROM gcr.io/forgerock-io/ds/docker-build:7.0.0-98f5024

USER forgerock 

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
