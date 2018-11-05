FROM forgerock-docker-public.bintray.io/forgerock/amster:6.5.0-M11

COPY scripts /opt/amster/scripts/
COPY config /opt/amster/config/
COPY secrets /var/run/secrets/amster/

USER root

RUN chown forgerock /var/run/secrets/amster/id_rsa*

USER forgerock
