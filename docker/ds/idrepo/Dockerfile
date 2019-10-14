FROM gcr.io/forgerock-io/ds-empty:7.0.0-37857fd088e5717cc3b8c9675d9937a183ab80e8

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh



