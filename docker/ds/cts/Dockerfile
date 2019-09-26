#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-5a575284741d4de9a2663172570b0aa234d71a46
# Pinned until PIT1 passes
FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-5a575284741d4de9a2663172570b0aa234d71a46

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
