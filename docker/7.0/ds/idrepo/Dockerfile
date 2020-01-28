FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-d1003ecdf6207d99846d2f50da5881a6d7b65069

COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock

# Workaround for # Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version" &&  rm bin/setup.sh
RUN bin/setup.sh "$profile_version"


