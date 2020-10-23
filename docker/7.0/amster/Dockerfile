FROM gcr.io/forgerock-io/amster:7.1.0-070e5fb109c783f6db3f80aaeb8b3ed5fa98d704

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
