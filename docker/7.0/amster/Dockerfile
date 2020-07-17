FROM gcr.io/forgerock-io/amster/pit1:7.0.0-7857ac4fe61e5e880708c938a0f5bec035a964b1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

