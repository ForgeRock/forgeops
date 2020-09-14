FROM gcr.io/forgerock-io/amster/pit1:7.1.0-a9a85dd05b9c181e2f8295ae5e660c860b0d279b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
