FROM gcr.io/forgerock-io/amster/pit1:7.1.0-b61a40ac2b200fa2bdad08e79a226e56343940c3

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
