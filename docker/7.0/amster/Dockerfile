FROM gcr.io/forgerock-io/amster:7.0.0-639d0f469ddc615364b1d5da27942ba8a54931e1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
