FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-950550a25ada2c77398871e632c8bd6bfd6d3aac
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh