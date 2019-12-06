FROM gcr.io/forgerock-io/amster/pit1:7.0.0-dc1310804b4bcba25a5db748c6a4873047bf66e0

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
