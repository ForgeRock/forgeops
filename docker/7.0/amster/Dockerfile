FROM gcr.io/forgerock-io/amster/pit1:7.0.0-6ca793903bffd174084369cedbfc69042757fd38

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
