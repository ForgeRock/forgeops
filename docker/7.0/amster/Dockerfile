FROM gcr.io/forgerock-io/amster/pit1:7.2.0-2021-6-4e7c36acf6254ec370ef9319c086c7d49cc8d8de

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

# This is needed to make amster happy. It wants to create a preferences directory
RUN chmod 777 /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
