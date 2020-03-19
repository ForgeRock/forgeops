FROM gcr.io/forgerock-io/amster/pit1:7.0.0-184e4c2bda9aa7df1ed416b7dcbbe9371a33e8f3

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
