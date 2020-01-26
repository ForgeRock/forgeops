FROM gcr.io/forgerock-io/amster:7.0.0-89af22ac7be5703138910c07b0179be2d827a8dd

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
