FROM gcr.io/forgerock-io/amster:7.0.0-697984eee231a709328320058d0fcefd00c68d26

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
