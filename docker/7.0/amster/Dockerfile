FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ac3f652afedfe6dce6bb4ee25a560b9de9ca956b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
