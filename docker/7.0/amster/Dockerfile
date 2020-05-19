FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1578692e746f9e5802be8e93b3569f9050fc3d7a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
