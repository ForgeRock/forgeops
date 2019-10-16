FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-e88c6fe9c4afe7126e2e13380d48a10d4c970c46

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh



