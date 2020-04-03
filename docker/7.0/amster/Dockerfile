FROM gcr.io/forgerock-io/amster/pit1:7.0.0-0976c0e80e9b8c5427c7db518979bba52908910a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
