FROM gcr.io/forgerock-io/ds-empty:7.0.0-1b0bc2295bb8bc16fe307671dc674f05bd712184

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
