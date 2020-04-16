FROM gcr.io/forgerock-io/ds-empty:7.0.0-56c28885e7c0cc242b5f552f812100b968c533fe
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
