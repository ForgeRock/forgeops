FROM gcr.io/forgerock-io/amster/pit1:7.1.0-05fc3346844ee5d4597a7c41a743b41d21ef82f2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
