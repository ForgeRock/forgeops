FROM gcr.io/forgerock-io/amster/pit1:7.0.0-de737def48b0d35c462b69c9e88b28167fdc87c1

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
