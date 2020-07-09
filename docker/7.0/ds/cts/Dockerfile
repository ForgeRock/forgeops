FROM gcr.io/forgerock-io/ds-empty:7.0.0-7a71773809eb975d0426fa885308e81b79d4b9f0
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh