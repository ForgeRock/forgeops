FROM gcr.io/forgerock-io/amster:7.1.0-f60d66cb6552d11258bfd3971494da11d188ece7

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
