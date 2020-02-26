FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-94f5a1e356c1365a9f6e00ecbec3903e9c4db8f5

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
