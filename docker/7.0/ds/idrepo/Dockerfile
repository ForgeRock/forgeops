FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-cc59a73bf4c7b7f3ad0aaf584705a0e2fad10471
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root idrepo /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh