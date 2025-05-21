ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/amster
ARG TAG=latest

FROM ${REPO}:${TAG}

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_OPTS="--no-install-recommends --yes"
RUN apt-get update \
        && apt-get install -y openldap-utils jq inotify-tools wget \
        && apt-get clean \
        && rm -r /var/lib/apt/lists /var/cache/apt/archives

RUN apt-get remove -y curl

USER forgerock

ENV SERVER_URI /am

ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /opt/amster
COPY --chown=forgerock:root scripts /opt/amster
# This is needed to make amster happy. It wants to create a preferences directory
RUN chmod 777 /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
