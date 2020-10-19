FROM gcr.io/forgerock-io/amster/pit1:7.1.0-76f2891a39e32755d2e17ec7520efccb9618eb7a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
