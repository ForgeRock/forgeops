FROM gcr.io/forgerock-io/amster/pit1:7.1.0-55c573bd0a04e7d7d76ed5dff081e75591db5110

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
