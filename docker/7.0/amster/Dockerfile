FROM gcr.io/forgerock-io/amster/pit1:7.0.0-84d968ebb460387ae8bd62370a5bdecaa1db05c7

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
