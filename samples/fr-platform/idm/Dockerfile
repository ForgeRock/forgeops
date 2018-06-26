FROM forgerock-docker-public.bintray.io/forgerock/openidm:6.0.0

USER root

RUN mkdir /tmp/workflow && \
    chown -R forgerock:forgerock /opt/openidm /tmp/workflow && \
    chmod 600 /opt/openidm/security/* && \
    chmod 755 /tmp/workflow

USER forgerock

COPY conf /opt/openidm/conf
COPY script /opt/openidm/script
COPY security /opt/openidm/security
COPY workflow /tmp/workflow
COPY ui /opt/openidm/ui

RUN mkdir /opt/openidm/workflow && \
    cd /tmp/workflow && \
    zip chess.bar chess* && \
    mv /tmp/workflow/chess.bar /opt/openidm/workflow
