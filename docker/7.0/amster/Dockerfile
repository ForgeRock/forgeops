FROM gcr.io/forgerock-io/amster/pit1:7.0.0-0b6369d39b7339715f56349abdb2d94b05b9084d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
