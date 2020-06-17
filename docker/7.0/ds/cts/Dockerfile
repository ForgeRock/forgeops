FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3e928f77855a379bb1e2f2f6ed4485dd0aa064c5
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh