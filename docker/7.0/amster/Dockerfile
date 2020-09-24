FROM gcr.io/forgerock-io/amster/pit1:7.1.0-ecc3ce91bdda3bd0e6df777a259111e7f8bc950c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
