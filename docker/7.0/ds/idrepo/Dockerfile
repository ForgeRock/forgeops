FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-491f2b6dae8c0810adb53a0ae981622c07c3f6c0

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
