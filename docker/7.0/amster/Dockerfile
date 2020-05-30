FROM gcr.io/forgerock-io/amster/pit1:7.0.0-a22ff7d60ed2f314082f0174920bdc754c14639c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
