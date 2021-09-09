FROM gcr.io/forgerock-io/amster:7.1.0-2021-4-71b17c4767aa491ddd6ff7417822fc856a2312a7

USER root

COPY debian-buster-sources.list /etc/apt/sources.list

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
