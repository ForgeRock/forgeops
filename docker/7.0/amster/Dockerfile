FROM gcr.io/forgerock-io/amster/pit1:7.0.0-f0f53bfea55332c01874aabb13e1306b7e1808a1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
