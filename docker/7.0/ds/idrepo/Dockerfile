FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-fc9ac0c308e05ddbd9532e4cf1d8800370084926

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version" && rm bin/setup.sh



