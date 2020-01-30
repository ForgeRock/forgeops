FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-aa0242e219a30fa1303bfcda75524a29a29e249d

COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock

# Workaround for # Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version" &&  rm bin/setup.sh
RUN bin/setup.sh "$profile_version"


