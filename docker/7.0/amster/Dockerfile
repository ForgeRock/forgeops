FROM gcr.io/forgerock-io/amster/pit1:7.1.0-IDCLOUD-ba6bb6ab62bda8049906827a62b5709c2eabb6aa

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
