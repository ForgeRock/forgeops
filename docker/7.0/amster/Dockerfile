FROM gcr.io/forgerock-io/amster/pit1:7.1.0-7e9682f6886aef2fcdf59c72d0efe310c859cbfd

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
