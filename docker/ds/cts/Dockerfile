FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-9a0eed54650c1b25f871fac524f7eda30ad24ad0

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
