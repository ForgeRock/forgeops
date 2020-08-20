FROM gcr.io/forgerock-io/amster/pit1:7.1.0-436314c267f7ce1269558926a2b14e572e7d6c16

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
