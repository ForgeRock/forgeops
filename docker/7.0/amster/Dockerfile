FROM gcr.io/forgerock-io/amster/pit1:7.0.0-5eb25b0d1051ae4137cfe17f27332b4693ef3ccc

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
