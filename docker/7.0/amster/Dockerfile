FROM gcr.io/forgerock-io/amster:7.1.0-IDCLOUD-363f9d83f7f9fbdea3259f8e1c66a65174c70a10

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
