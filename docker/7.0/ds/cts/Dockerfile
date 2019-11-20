FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-4ab0993f331d33909de012059d1987b164a2f368

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh
