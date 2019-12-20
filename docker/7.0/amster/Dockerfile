FROM gcr.io/forgerock-io/amster:7.0.0-4d555a27df019be2ef0af4632f01c8fba9fa6ee4

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
