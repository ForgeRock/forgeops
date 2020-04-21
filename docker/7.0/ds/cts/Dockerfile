FROM gcr.io/forgerock-io/ds-empty:7.0.0-3611cd579e40af4eb72594f08fb27b3ad77e4194
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
