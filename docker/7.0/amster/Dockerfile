FROM gcr.io/forgerock-io/amster:7.0.0-3879c68645a0b0c6ff9d6a9a0a295d12e32a22d9

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
