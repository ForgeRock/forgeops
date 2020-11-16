FROM gcr.io/forgerock-io/ds/pit1:7.1.0-1c29fa286cb61b712a2519d2a0660ca0226296b5
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root common  /opt/opendj/
COPY --chown=forgerock:root cts     /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version" && \
    bin/relax-security-settings.sh  && \
    rm bin/setup.sh bin/relax-security-settings.sh
