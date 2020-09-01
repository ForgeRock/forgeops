FROM gcr.io/forgerock-io/amster/pit1:7.1.0-b308cddf4ace417ce012199460445581f5c5c285

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
