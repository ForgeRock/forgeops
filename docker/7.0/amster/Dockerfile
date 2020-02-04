FROM gcr.io/forgerock-io/amster:7.0.0-fd2935e0193e742ce79c3e421ff05bcdbd9f6f37

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
