FROM gcr.io/forgerock-io/ds-empty:7.0.0-bc692008636cf9520635e83b767bf158b5360671

COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock

# Workaround for # Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version" &&  rm bin/setup.sh
RUN bin/setup.sh "$profile_version"


