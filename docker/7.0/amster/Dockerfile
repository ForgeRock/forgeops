FROM gcr.io/forgerock-io/amster/pit1:7.1.0-b5d389795c5edbfb2b66cf1034e21c8aee2a91b8

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
