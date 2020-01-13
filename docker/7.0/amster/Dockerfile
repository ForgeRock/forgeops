FROM gcr.io/forgerock-io/amster/pit1:7.0.0-daa683b43ba84ec8fd0f565311d8370d49b7acda

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
