# The ds-empty image configures https/https, and monitoring
FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-latest-postcommit
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
