FROM gcr.io/forgerock-io/amster/pit1:7.0.0-fb5f17e93a1a4939b01b3554dcc58d74fc8456dc

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
