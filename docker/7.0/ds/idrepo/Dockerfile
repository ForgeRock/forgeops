FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-a7832b78eb5115a7b6eb56d6084983b04aa8e933

COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock

# Workaround for # Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version" &&  rm bin/setup.sh
RUN bin/setup.sh "$profile_version"


