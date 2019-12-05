FROM gcr.io/forgerock-io/amster/pit1:7.0.0-372834053484c48f979460c5972368a629de2c7b

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
