FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-a6078d84e568f285f6d42513e04a4248e19ef77f

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
