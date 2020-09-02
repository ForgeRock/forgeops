FROM gcr.io/forgerock-io/amster/pit1:7.1.0-f0248b84a4ed9100c5b97a4bb78ccdaf6cb88558

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
