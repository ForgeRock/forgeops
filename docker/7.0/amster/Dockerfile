FROM gcr.io/forgerock-io/amster:7.1.0-40ed6c8666f103e0666ef43fef04103d533863bd

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
