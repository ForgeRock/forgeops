FROM gcr.io/forgerock-io/amster:7.0.0-535669158fd0ae2f3516118ca08c4bbb306cbed1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
