FROM gcr.io/forgerock-io/amster:7.0.0-61aa3c4d88eacb1253566d6fba6d772ca88c5d74

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
