FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3304cd99e26487eb57a2522fc269478d63741ef1
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root idrepo /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh