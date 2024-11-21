ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/ig
ARG TAG=latest

FROM ${REPO}:${TAG}

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /var/ig
COPY --chown=forgerock:root . /var/ig
