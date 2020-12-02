FROM gcr.io/forgerock-io/amster/pit1:7.1.0-69b22d62d9b796b2faa0c83692c5b32c34f662ba

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
