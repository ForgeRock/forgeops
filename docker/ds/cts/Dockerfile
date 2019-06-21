FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-latest-postcommit

USER forgerock 

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
