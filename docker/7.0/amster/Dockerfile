FROM gcr.io/forgerock-io/amster/pit1:7.1.0-5d3481ee37cc5b462b14d954c6005318e869d309

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
