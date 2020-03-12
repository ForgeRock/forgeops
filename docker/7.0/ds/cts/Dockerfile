FROM gcr.io/forgerock-io/ds-empty:7.0.0-afce02b7cc411eb41758d0b9cd3a3d4471782633

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
