FROM gcr.io/forgerock-io/amster:7.0.0-5484608da8efa9d48f1fe4cc113c8ce529bcf591

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
