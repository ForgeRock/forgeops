FROM gcr.io/forgerock-io/amster:7.0.0

USER root
RUN apt-get update && apt-get install -y openldap-utils jq  && apt-get clean \
        && rm -r /var/lib/apt/lists /var/cache/apt/archives

USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
