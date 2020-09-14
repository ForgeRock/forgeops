FROM gcr.io/forgerock-io/amster/pit1:7.1.0-7da87619d0ccd4341663ea24743b19d94186b359

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
