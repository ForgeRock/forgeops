FROM gcr.io/forgerock-io/amster/pit1:7.0.0-7af2bdeee6d3694e40871a794eea5613eea5b075

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
