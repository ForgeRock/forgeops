FROM gcr.io/forgerock-io/ds-empty:7.0.0-fc9ac0c308e05ddbd9532e4cf1d8800370084926

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh



