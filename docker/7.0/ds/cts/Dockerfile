FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-f7a0346ae15eae49a154d5cf7f2ed0ed31f551c6

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
