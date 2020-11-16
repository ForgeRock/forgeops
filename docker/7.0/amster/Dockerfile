FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2020-14-d364e7e5abbaa5356728c9dbe611b49eae2c3c2a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
