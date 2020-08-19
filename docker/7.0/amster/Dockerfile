FROM gcr.io/forgerock-io/amster/pit1:7.1.0-a8e402feaaef069248bd3d864a4728af445fe5ae

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
