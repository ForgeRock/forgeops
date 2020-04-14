FROM gcr.io/forgerock-io/amster/pit1:7.0.0-62edef63fc818a1ac7a668ce7c1b4bbbfce13de5

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
