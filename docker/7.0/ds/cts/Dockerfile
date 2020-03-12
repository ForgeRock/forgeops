FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3b1414b66f4defde10ce0f73c82c15e9a956568e

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
