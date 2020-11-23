FROM gcr.io/forgerock-io/amster/pit1:7.1.0-c843b51618f1502787d86e6013609efb3c530fd7

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
