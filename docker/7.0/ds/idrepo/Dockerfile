FROM gcr.io/forgerock-io/ds-empty:7.0.0-c9119f11bf4fcadcfa5d88b3d0d6f5c8fa5ec6a1
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root idrepo /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
