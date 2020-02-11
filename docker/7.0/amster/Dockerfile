FROM gcr.io/forgerock-io/amster/pit1:7.0.0-958a8afbdd7ef916330994bb993eba8886b2ce5e

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
