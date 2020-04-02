FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-337205ea29cf85ef6a6a6623939603301cb6940e
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
