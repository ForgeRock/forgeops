FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-94ff565b53d526d14dcd65e0d965e7976d08f024
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
