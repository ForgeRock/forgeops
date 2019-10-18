FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-9a0eed54650c1b25f871fac524f7eda30ad24ad0

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh



