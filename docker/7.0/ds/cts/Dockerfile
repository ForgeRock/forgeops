FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-4bdf129240b80ce4e1b1ad657df4a9cb24589657

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
