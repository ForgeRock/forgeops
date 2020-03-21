FROM gcr.io/forgerock-io/ds-empty:7.0.0-335edbf99f43c3e9b341ad244a4e4586f6888ac5
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
