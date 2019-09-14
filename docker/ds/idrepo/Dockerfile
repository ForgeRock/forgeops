# The ds-empty image configures https/https, and monitoring
#FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-latest-postcommit
# Pinned until https://bugster.forgerock.org/jira/browse/OPENDJ-6556 is fixed
FROM gcr.io/forgerock-io/ds-empty/docker-build@sha256:e7b0bd12c92cc1d74872ad747d3faa50872fe61b436d918e10eb7599bff4ea3f
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
