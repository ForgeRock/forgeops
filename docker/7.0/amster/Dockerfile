FROM gcr.io/forgerock-io/amster/pit1:7.0.0-4b04f7b69602a5ac8b849bc31fd0e9dbbc2c51a1

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
