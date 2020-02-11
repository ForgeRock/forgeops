FROM gcr.io/forgerock-io/ds-empty:7.0.0-527044f9490d5b7e2a865d9c730c362aa8cf3910

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
