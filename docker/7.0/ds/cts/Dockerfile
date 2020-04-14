FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-47385d8ddaf002f3697838913e7e6b8798892462
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
