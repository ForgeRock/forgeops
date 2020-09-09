FROM gcr.io/forgerock-io/amster:7.1.0-b7a36baba378e92b6c827089acd29032f780fcbf

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
