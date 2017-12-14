FROM forgerock/openidm:latest

COPY bundle /opt/openidm/bundle
COPY conf /opt/openidm/conf
COPY script /opt/openidm/script
COPY security /opt/openidm/security

USER root
RUN chown -R forgerock:forgerock /opt/openidm && \
    chmod 600 /opt/openidm/security/*
USER forgerock
