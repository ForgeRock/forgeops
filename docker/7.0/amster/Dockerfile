FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ffc966cd25c7954437d2b97d0c163c7aacd687ff

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
