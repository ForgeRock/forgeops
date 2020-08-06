FROM gcr.io/forgerock-io/amster/pit1:7.0.0-a7f76b349ac6c4eb6472596d33b5abc133db41bb

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
