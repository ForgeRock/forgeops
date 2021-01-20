FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2020-15-e76250c6839e794a256876a828c650422b6575fa

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
