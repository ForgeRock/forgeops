FROM gcr.io/forgerock-io/ds-empty:7.0.0-34ba032f063894183622f87a0074d122af9bbb3b

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
