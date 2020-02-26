FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1fcb34289a421bb7827e394e509c678e39f84432

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
