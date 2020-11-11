FROM gcr.io/forgerock-io/amster/pit1:7.1.0-1f5069f7a044d99a0942222dcea9cd8a21f792bf

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
