FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-d04efe93e947ab886d9dbfa0952c0600d791361c
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh