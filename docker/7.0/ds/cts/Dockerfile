FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-43df014e3c9c1a04855682c37e172d34c85bd6e2
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh