FROM gcr.io/forgerock-io/amster:7.1.0-0b3af0bf037ad5a7ef68c6806193e240a9bd69ab

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
