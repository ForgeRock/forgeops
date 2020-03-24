FROM gcr.io/forgerock-io/amster/pit1:7.0.0-e8dcd2ac25186a82ea68713ee4a8b20852639540

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
