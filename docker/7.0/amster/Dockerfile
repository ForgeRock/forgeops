FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d167b6d778bd46035de1f229debad266e9b975a4

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

