FROM gcr.io/forgerock-io/amster/pit1:7.0.0-71ce2d7acb3d76c00ff5bdb9c6f12ee8e1ffe4ff

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
