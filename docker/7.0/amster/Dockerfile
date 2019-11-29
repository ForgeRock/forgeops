FROM gcr.io/forgerock-io/amster/pit1:7.0.0-6572366009892afeda6b66749738cfbde2da0858

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
