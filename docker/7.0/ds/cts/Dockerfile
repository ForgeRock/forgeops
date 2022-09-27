FROM gcr.io/forgerock-io/ds/pit1:7.1.4-3bac90e025aac529d0bd2b6f15bd72290f4f2640
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
