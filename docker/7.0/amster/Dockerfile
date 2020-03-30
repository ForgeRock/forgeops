FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c3b737f88efdb50883693f2d04fddf08de3d0673

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
