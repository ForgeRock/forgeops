FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-d8c18771e8c09d86bffd6ca2108cb9065e8fd861

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
