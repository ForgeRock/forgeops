FROM gcr.io/forgerock-io/amster/pit1:7.1.0-706b2ef731ece59cf9a0587789fb2cc9aa04ee74

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
