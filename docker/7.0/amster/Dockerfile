FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ff8d8a21f35cec203ece6bc8d4f827ff44fa6e6b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
