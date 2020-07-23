FROM gcr.io/forgerock-io/amster/pit1:7.0.0-90277083e827b8323664cea97d3ed5920338d235

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

