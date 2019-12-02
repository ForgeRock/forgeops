FROM gcr.io/forgerock-io/amster:7.0.0-9c65209f1fd47cff671a02ce754d8d5fadc7d826

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
