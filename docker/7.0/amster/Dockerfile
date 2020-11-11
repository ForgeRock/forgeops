FROM gcr.io/forgerock-io/amster/pit1:7.1.0-65cd3426e76a2cc60c342c95b2a85003cabbc605

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
