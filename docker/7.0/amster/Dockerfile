FROM gcr.io/forgerock-io/amster:7.0.0-6d4039907df69775a3852c7be22227a9fb096a49

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
