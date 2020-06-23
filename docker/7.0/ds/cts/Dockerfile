FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-ac58ac55a2fb6ace463fa251c3651b6f6d632354
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh