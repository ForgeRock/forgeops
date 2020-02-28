FROM gcr.io/forgerock-io/amster:7.0.0-98fae1caa4a90fadb8001e2753b290bce7b784e6

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
