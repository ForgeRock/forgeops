FROM gcr.io/forgerock-io/ds-empty:7.0.0-f523bf277ea9beb0ba2e926115a80084f1434538

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
