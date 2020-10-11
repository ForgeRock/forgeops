FROM gcr.io/forgerock-io/amster:7.1.0-709a7b5327a3d64f7b341aa13df80404cedbb250

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
