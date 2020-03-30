FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ec7a657fa79521b76fd3ee424aa1d80e09992a5f

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
