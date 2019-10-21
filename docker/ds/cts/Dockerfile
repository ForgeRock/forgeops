FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-7ef42d9a34b5b829d10ca251e6a17d6eff93d678

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
