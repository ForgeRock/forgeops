FROM gcr.io/forgerock-io/amster/pit1:7.0.0-cdb024a278f436058dcfd9f72ecfed1ba9e775a4

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
