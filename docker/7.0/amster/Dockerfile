FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2021-3-9570c1b6957db7c2f7a835ac14fa35ae5d1223b5

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_OPTS="--no-install-recommends --yes"
RUN apt-get update \
        && apt-get install -y openldap-utils jq inotify-tools \
        && apt-get clean \
        && rm -r /var/lib/apt/lists /var/cache/apt/archives

USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
