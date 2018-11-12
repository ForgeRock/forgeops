FROM forgerock-docker-public.bintray.io/forgerock/openidm:6.5.0-M7

USER root

RUN chmod 600 /opt/openidm/security/*

USER forgerock

COPY conf /opt/openidm/conf
COPY script /opt/openidm/script
COPY security /opt/openidm/security
