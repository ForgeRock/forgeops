FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-bf5ed405ca2b60abf1cd533bc82321b0ccfe0cfa

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
