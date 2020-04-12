FROM gcr.io/forgerock-io/ds-empty:7.0.0-a6c441083413c930d483de6b357da690a529144b
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
