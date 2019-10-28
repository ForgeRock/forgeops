FROM gcr.io/forgerock-io/ds-empty:7.0.0-7ef42d9a34b5b829d10ca251e6a17d6eff93d678

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh
