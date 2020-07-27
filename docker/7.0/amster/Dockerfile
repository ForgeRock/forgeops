FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c1dfe08a3e5f8e21c571268833651023447f0024

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

