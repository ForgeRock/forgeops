FROM gcr.io/forgerock-io/amster/pit1:7.1.0-ad9752989e87287b50203411ab3fc8a9fde6b452

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
