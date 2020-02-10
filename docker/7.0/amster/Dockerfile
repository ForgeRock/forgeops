FROM gcr.io/forgerock-io/amster/pit1:7.0.0-a187066683ee9b57b69c24a200b3ae872ffc9452

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
