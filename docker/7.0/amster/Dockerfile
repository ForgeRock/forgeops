FROM gcr.io/forgerock-io/amster/pit1:7.1.0-9982b798bb67552fcdcd62a8980997db5643f864

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
