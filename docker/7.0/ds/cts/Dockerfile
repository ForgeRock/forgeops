FROM gcr.io/forgerock-io/ds-empty:7.0.0-5b1b0373e22848c4d70c059cb26175f83892b1c8

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
