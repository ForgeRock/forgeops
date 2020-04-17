FROM gcr.io/forgerock-io/ds-empty:7.0.0-9636e4826c61876d2825dffb85e2e92d4286ff46
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
