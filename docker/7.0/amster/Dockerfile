FROM gcr.io/forgerock-io/amster/pit1:7.0.0-4a1478c6b9eafa0b847751d5911134db719b721a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
