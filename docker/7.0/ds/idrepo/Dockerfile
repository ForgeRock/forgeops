FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-5645da5b8854d00de69cfc1a42c662d9ac495d60

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh



