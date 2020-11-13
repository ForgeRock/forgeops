FROM gcr.io/forgerock-io/amster/pit1:7.1.0-IDCLOUD-d136098c4a0693ff03b34472eed0552ed8e1f57e

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
