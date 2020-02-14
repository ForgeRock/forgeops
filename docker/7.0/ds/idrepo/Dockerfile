FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-cceccaccf06fc51987645514a4d2dd17fe0a1c1f

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
