FROM gcr.io/forgerock-io/ds/pit1:7.1.0-2021-2-a242eb14ac3bcbdb4d9491993cb57bdf094ad2b6
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
