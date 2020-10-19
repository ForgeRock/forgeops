FROM gcr.io/forgerock-io/amster/pit1:7.1.0-f9932d17155f51ed748612133c0cae3207085977

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
