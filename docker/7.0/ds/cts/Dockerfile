FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-6548ef3540364d400755e76a2d372dd8e608ef2b
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
