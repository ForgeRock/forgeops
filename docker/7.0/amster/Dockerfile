FROM gcr.io/forgerock-io/amster/pit1:7.1.0-96cadb24b2c8e49b1c8e0bac42ef059954b6abc1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
