FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-af705fedbb4255c77ed7ab5b57bfa71d6b9bcdfe

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
