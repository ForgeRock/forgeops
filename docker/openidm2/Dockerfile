FROM forgerock-docker-public.bintray.io/forgerock/openidm:6.0.0

USER root

RUN chown -R forgerock:forgerock /opt/openidm && \
    chmod 600 /opt/openidm/security/*

USER forgerock

COPY conf /opt/openidm/conf
COPY script /opt/openidm/script
COPY security /opt/openidm/security
