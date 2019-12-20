FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-7dd37a8e20fc05c8a88cf1a02ef5d4b3a5092c38

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
