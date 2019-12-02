FROM gcr.io/forgerock-io/amster:7.0.0-6f9c62c199c95823fa82cfe42a18ea5df6a194c1

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
