FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8a2de059a7b003d3d415164b0629ffbdb09d385d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
