FROM gcr.io/forgerock-io/amster/pit1:7.0.0-15ee695123014cf0c35305160c42388eed54fc72

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
