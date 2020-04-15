FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c9242a8316ce8915eecadb09a60858aa5b5fe63a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
