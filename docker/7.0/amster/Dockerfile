FROM gcr.io/forgerock-io/amster:7.0.0-3a8646ed346fa9e7a399ecc6caacc4a39140103b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
