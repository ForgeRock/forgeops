FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1f9575cd42cba588d83f0edec4fc32e3256270ec

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
