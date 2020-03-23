FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-a7810fc3daf5f33d3ebe8d53f369d14f674405a3
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
