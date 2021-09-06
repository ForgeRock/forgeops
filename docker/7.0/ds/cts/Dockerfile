FROM gcr.io/forgerock-io/ds/pit1:7.1.1-c63fdca731f885da9cabe4a16d560e8ac9d4fb1f
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
