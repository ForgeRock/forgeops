FROM gcr.io/forgerock-io/amster/pit1:7.1.0-a5e58eb76f7853d3cf90529e851dd3627d9d55ce

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
