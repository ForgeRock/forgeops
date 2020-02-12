FROM gcr.io/forgerock-io/amster/pit1:7.0.0-02517c3f1ac0c2baabb854bd517bdeff22beed30

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
