FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-038e4f769278e4cb98ec8edfca16b1154e869d32

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh
