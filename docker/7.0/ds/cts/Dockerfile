FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-c8023812572ea39b1ea02ec1bb22a18d6b076b77

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
