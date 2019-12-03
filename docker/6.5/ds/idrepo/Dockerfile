# Use publicly available ds image for evaluation
FROM gcr.io/forgerock-io/ds:6.5.2

# Use a custom ds-base image. See forgeops/docker/6.5/am-base/README
#FROM ds-base:latest

USER forgerock 

COPY --chown=forgerock:root .  /opt/opendj/
