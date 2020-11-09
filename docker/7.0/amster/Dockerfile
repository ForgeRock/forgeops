FROM gcr.io/forgerock-io/amster/pit1:7.1.0-c479bd5724a87f418c244a35901131a47d407e72

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
