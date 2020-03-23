FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-857d5bf296343be7b41731ffbcd9acf7f3ab387d
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
