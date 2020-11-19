FROM gcr.io/forgerock-io/amster/pit1:7.1.0-65e1851883a14f61b7458e9bc49d8447bf41b7b2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
