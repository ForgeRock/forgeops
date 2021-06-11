FROM gcr.io/forgerock-io/amster/pit1:7.2.0-37b2f4b402112cd1467893154a0f54acbca50a0c

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_OPTS="--no-install-recommends --yes"
RUN apt-get update \
        && apt-get install -y openldap-utils jq inotify-tools \
        && apt-get clean \
        && rm -r /var/lib/apt/lists /var/cache/apt/archives

USER forgerock

ENV SERVER_URI /am

ARG CONFIG_PROFILE=cdk
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /opt/amster
COPY --chown=forgerock:root . /opt/amster

# This is needed to make amster happy. It wants to create a preferences directory
RUN chmod 777 /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
