FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8f969e9594a432cb5d850667f1f65afd5a9fcc55

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
