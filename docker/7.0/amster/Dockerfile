FROM gcr.io/forgerock-io/amster/pit1:7.0.0-a6e287d9207e523887da8b258a89f7475c3eb856

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
