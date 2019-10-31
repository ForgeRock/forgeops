FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-9c922d2256a731bbbf96a38dc9ba217e8eb53423

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh
