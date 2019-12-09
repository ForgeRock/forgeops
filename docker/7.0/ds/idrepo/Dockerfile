FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3a22331096cf2bcffe53ea0d34c26059ff1535a4

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version" && rm bin/setup.sh



