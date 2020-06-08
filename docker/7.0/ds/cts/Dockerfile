FROM gcr.io/forgerock-io/ds-empty:7.0.0-b0222b47da54d2a1f79763af965ac1c240e63fb4
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
