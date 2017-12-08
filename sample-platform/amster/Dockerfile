FROM forgerock/amster:5.5.1

COPY scripts /opt/amster/scripts/
COPY config /opt/amster/config/

USER root

RUN mkdir -p /var/run/secrets/amster/ && \
    ssh-keygen -f /var/run/secrets/amster/id_rsa -P "" -q && \
    chown forgerock /var/run/secrets/amster/id_rsa*

USER forgerock
