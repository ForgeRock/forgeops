FROM gcr.io/forgerock-io/ds:7.2.0-2021-5-0d96fa18701ab26e52954ca0f8b41236b3c99383
USER root

COPY debian-buster-sources.list /etc/apt/sources.list

RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root common  /opt/opendj/
COPY --chown=forgerock:root cts     /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh && \
    bin/relax-security-settings.sh  && \
    rm bin/setup.sh bin/relax-security-settings.sh
