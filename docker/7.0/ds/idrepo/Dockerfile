FROM gcr.io/forgerock-io/ds-empty:7.0.0-4ec9c91cacb5a2f1d7b17933948e6fe175dc030a

COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock

# Workaround for # Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version" &&  rm bin/setup.sh
RUN bin/setup.sh "$profile_version"


