#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-latest-postcommit
# Pinned until https://bugster.forgerock.org/jira/browse/OPENDJ-6556 is fixed
FROM gcr.io/forgerock-io/ds-empty/docker-build@sha256:39bb0e938007a5855d35c0f800a3068bd41af164988e3d60431dbc5e33a4fd52

USER forgerock 

RUN setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
