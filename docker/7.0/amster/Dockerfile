FROM gcr.io/forgerock-io/amster:7.1.0-b10ed700537130a1b5f97211f8362551a87a6f9e

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
