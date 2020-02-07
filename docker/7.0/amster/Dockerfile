FROM gcr.io/forgerock-io/amster/pit1:7.0.0-5f59408206296df36cb122ba9cff3cfc9142a45b

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
