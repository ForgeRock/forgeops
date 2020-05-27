FROM gcr.io/forgerock-io/amster:7.0.0-eb2ce48b2fa6f42f9928acdb5b2a22f7ff988865

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
