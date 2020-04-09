FROM gcr.io/forgerock-io/amster:7.0.0-d4ff89d9be945d99146e6c5ea2a0d1df20151a9c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
