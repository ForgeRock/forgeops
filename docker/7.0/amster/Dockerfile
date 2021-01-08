FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2020-15-c262a7a805d31588c08170dd030f843d3658cc4a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
