FROM gcr.io/forgerock-io/ds-empty/docker-build:7.0.0-af8f1cb83f6b279dd3613fcaf468c12886041aa2

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh



