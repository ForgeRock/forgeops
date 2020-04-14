FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3b6e8b6546bd7ad6549e27bfbb06524cc32c68e3
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
