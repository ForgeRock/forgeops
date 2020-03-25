FROM gcr.io/forgerock-io/amster:7.0.0-b1048dc194ff708807cd7b466a7855dc2356e031

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
