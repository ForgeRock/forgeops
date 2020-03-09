FROM gcr.io/forgerock-io/amster/pit1:7.0.0-fed0889f9ef911c852a73fd7ff0a6ba03f74650d

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
