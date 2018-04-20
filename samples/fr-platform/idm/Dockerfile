FROM forgerock-docker-public.bintray.io/forgerock/openidm:6.0.0

COPY conf /opt/openidm/conf
COPY script /opt/openidm/script
COPY security /opt/openidm/security
COPY workflow /tmp/workflow
COPY ui /opt/openidm/ui

USER root

RUN mkdir /opt/openidm/workflow && \
    cd /tmp/workflow && \
    zip chess.bar chess* && \
    mv /tmp/workflow/chess.bar /opt/openidm/workflow

RUN chown -R forgerock:forgerock /opt/openidm && \
    chmod 600 /opt/openidm/security/*
USER forgerock
