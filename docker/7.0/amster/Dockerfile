FROM gcr.io/forgerock-io/amster:7.0.0-d158df4bee33faad8c169c677f3cd25db2e30a00

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
