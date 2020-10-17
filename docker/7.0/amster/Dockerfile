FROM gcr.io/forgerock-io/amster/pit1:7.1.0-b97c1bf327c28b038f310a15a95854ed7293a818

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
