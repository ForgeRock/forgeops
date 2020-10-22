FROM gcr.io/forgerock-io/amster/pit1:7.1.0-ed2ecac6787b21654be6a3a8738fb5e44b782899

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
