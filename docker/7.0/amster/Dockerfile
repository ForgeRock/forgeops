FROM gcr.io/forgerock-io/amster:7.0.0-810c6700800d99c391fae0efcf936fa59a2ab29a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
