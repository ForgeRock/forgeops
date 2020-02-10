FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-527044f9490d5b7e2a865d9c730c362aa8cf3910

COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock

# Workaround for # Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version" &&  rm bin/setup.sh
RUN bin/setup.sh "$profile_version"


