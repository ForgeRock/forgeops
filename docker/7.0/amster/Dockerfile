FROM gcr.io/forgerock-io/amster/pit1:7.0.0-59ca7e70f9d8cac7837f1c5850add9bd93a733d9

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
