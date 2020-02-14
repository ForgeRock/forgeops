FROM gcr.io/forgerock-io/ds-empty:7.0.0-9b2afa4cf0038cff6fa9d29cd416347378ae672a

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
