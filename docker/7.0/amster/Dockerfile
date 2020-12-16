FROM gcr.io/forgerock-io/amster:7.1.0-4620b7299064d0d2441c829ea7d46e7390e85e2a

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_OPTS="--no-install-recommends --yes"
RUN apt-get update \
        && apt-get install -y openldap-utils jq \
        && apt-get clean \
        && rm -r /var/lib/apt/lists /var/cache/apt/archives

USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
