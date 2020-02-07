FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-236c314e083f8b4b25725f5dc3fb5b63f823c132

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
