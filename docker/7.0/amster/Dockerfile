FROM gcr.io/forgerock-io/amster/pit1:7.0.0-333fbfa3188f721711fe34930266ccc77d0c8161

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
