FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8de93c84424274d4c7b6a71c7b089d5139e45b8a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

