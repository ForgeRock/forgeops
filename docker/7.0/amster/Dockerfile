FROM gcr.io/forgerock-io/amster:7.0.0-9d6cb9aa8c135d972fdbbe637caaede4fa04705e

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
