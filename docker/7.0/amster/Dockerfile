FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8d16ea84e5147b7e33ba57630e066ef08e7200d5

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
