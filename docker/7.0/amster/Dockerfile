FROM gcr.io/forgerock-io/amster/pit1:7.1.0-3c8a968c2ee239a7234faf36368ac2d835798172

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
