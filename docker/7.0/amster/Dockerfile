FROM gcr.io/forgerock-io/amster/pit1:7.0.0-316332fa3a115b4154e21f16f2229cf470106917

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
