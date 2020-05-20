FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b1a1c6c050823006ce23a0d03f288544ac086a94

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
