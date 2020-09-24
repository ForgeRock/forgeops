FROM gcr.io/forgerock-io/amster/pit1:7.1.0-ecdfac933d89308e4c5ba2e00074ce095656b2ff

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
