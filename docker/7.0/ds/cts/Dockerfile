FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3a0cf0cc28245c3610c7d1888b711e5ff6d8abd0
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
