FROM gcr.io/forgerock-io/amster/pit1:7.1.0-51705a5e9c075c66cb76e371f725832b777c5eb2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
