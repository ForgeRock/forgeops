FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b8634753c6cca43b228b029da6e62cc61d0357f3

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

