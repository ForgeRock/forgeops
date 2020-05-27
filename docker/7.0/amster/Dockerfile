FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ac8654b42fcc0bd98f8ed4525282c7acecc283ca

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
