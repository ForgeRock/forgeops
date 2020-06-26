FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-6d8b68c4e0545a3f7ecc953d46a6c8486084a299
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root idrepo /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh