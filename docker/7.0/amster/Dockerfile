FROM gcr.io/forgerock-io/amster/pit1:7.0.0-73909938927397395535c6ac6d17f8870faea25f

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
