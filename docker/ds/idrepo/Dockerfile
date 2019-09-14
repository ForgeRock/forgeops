# The ds-empty image configures https/https, and monitoring
#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-latest-postcommit
# Pinned until https://bugster.forgerock.org/jira/browse/OPENDJ-6556 is fixed

FROM gcr.io/forgerock-io/ds-empty/docker-build@sha256:5f406320293c492c0497aec9bc72f6991630a0ab65d49996e0f551d9aeb9457f
#FROM gcr.io/forgerock-io/ds-empty/docker-build@sha256:0e6b21e53ece8e937351d09a054732a229c870af876e7f67ba7b52a1b6c5a7d6

USER forgerock 

RUN setup-profile --profile am-config \
                  --set am-config/amConfigAdminPassword:password \
 && setup-profile --profile am-identity-store \
                  --set am-identity-store/amIdentityStoreAdminPassword:password \
 && setup-profile --profile idm-repo \
                  --set idm-repo/domain:forgerock.io \
 && setup-profile --profile am-cts \
                  --set am-cts/tokenExpirationPolicy:ds \
                  --set am-cts/amCtsAdminPassword:password

COPY --chown=forgerock:root .  /opt/opendj/
