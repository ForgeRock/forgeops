FROM gcr.io/forgerock-io/amster/pit1:7.0.0-16127071c282cc089de2e955627a2ec70ce2eacb

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
