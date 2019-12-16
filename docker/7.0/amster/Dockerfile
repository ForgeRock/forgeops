FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8ef88f90bfddf5c31a2e57cc19856ae07a60fa0b

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
