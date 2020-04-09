FROM gcr.io/forgerock-io/amster/pit1:7.0.0-74b0960b56bd322df8e340ff5315b190ad1079f2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
