FROM gcr.io/forgerock-io/amster:7.0.0-93da886e8e14e4e885962d1e45cec795cf7942aa

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
