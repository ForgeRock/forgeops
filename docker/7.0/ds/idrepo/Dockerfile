FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-a2ab509ddd93741be9fae624a5207ca84cda37e6
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
