FROM gcr.io/forgerock-io/ds-empty:7.0.0-e10149f67781091f21008f3417ed5a50bd6c8dd4

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
