FROM gcr.io/forgerock-io/amster:7.1.0-PAAS-GA-9ef0947b48cfbf2c592f7d21a9788539c96c61a1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
