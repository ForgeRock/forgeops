FROM gcr.io/forgerock-io/amster/pit1:7.0.0-3193e980af1a82d274dd902e8b7f4678c27102b7

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
