FROM gcr.io/forgerock-io/amster/pit1:7.0.0-322e771885e3cd11e80995b680220ea46460585f

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
