FROM gcr.io/forgerock-io/amster/pit1:7.1.0-5cc003ddb45d3a6bebf0818368da366997350473

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
