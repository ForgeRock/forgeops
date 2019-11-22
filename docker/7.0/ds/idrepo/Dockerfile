FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-c82ab9b02f0a142228a98a6428307962782e966b

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh



