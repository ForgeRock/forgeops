FROM gcr.io/forgerock-io/amster/pit1:7.0.0-497057cd2ef6ed8ae8d0b80387b8587764188c7c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
