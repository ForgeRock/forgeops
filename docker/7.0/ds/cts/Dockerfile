FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-095a2cf13c1e0d2baed14f999247f1195a00bd40
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh