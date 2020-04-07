FROM gcr.io/forgerock-io/amster/pit1:7.0.0-f3a5c2da84fec0fe2f3e2958c14c55e230091fa8

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
