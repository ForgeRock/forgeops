FROM gcr.io/forgerock-io/amster/pit1:7.1.0-ea21b8c717660ffc50d98b3fc529446d8fb40413

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
