FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-512c15d241278e5e62e0a789d8dfb0b2f941d4d3

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version" && rm bin/setup.sh



