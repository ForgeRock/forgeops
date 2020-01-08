FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b95ce9a91750bd6055aad5b4d2fe1934357bcc58

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
