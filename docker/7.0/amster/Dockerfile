FROM gcr.io/forgerock-io/amster/pit1:7.0.0-4249169dae611fb69df851e5f431e9e4980df849

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
