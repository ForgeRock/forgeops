FROM gcr.io/forgerock-io/amster:7.0.0-b3d4f29e7212a9b4f8631b010b17ee6e7cabc117

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
