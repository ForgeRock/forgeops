FROM forgerock/openidm:latest

COPY bundle /opt/openidm/bundle
COPY conf /opt/openidm/conf
COPY script /opt/openidm/script

USER root
RUN chown -R forgerock:forgerock /opt/openidm
USER forgerock
