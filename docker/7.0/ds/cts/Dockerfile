FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-df497aa65423f1d43455a2b7d576ba63f57d95f3

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
