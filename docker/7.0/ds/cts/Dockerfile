FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-bd674c8221bb93edbfaa720e882a3a24f129519c
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh