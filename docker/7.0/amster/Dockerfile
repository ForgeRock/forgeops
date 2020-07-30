FROM gcr.io/forgerock-io/amster/pit1:7.0.0-008fde63cfa122a3b9f30abf2ccfdab51b7965d1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

