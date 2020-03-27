FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ca3d8a26b165cfe05efaa5e3cbb3ce975ffd1092

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
