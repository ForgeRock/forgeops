FROM gcr.io/forgerock-io/ds/pit1:7.1.0-c12d7230a8c22b3d588a61b09e1d2d62dd559f0b
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root common  /opt/opendj/
COPY --chown=forgerock:root cts     /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh && \
    bin/relax-security-settings.sh  && \
    rm bin/setup.sh bin/relax-security-settings.sh
