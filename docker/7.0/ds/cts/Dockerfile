FROM gcr.io/forgerock-io/ds-empty:7.0.0-9b4c75a9f01f862ddd0e4c879c3a9a8b9009d202

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
