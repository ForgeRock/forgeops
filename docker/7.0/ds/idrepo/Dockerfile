FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-811df5ce22a58995d94ad7f34e6552e9e8b4a8c0
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
