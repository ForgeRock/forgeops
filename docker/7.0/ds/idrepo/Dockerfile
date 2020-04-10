FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-88d7753d05cc110415201771cfd5711706f105dc
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
