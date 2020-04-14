FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d21d43d2eaeeaf295ed59c80868fd2e1fd6f3b0b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
