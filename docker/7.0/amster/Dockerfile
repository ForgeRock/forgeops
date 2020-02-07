FROM gcr.io/forgerock-io/amster:7.0.0-e2858fd0d72ee63bed20834e46d8276b8806229f

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
