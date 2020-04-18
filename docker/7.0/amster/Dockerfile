FROM gcr.io/forgerock-io/amster/pit1:7.0.0-007878d135fb859c709c1c7c03ddccb582c9b2f5

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
