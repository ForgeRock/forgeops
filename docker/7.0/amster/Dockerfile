FROM gcr.io/forgerock-io/amster/pit1:7.0.0-a52fe0b389ccbcab88c84264442a748a9ce1ff33

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
