FROM gcr.io/forgerock-io/ds-empty/docker-build:latest

RUN setup-profile --profile am-config \
                  --set am-config/amConfigAdminPassword:password \
 && setup-profile --profile am-identity-store \
                  --set am-identity-store/amIdentityStoreAdminPassword:password \
 && setup-profile --profile idm-repo

COPY --chown=forgerock:root .  /opt/opendj/
