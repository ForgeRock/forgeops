FROM gcr.io/forgerock-io/ig:2023.6.0

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
ARG CONFIG_PROFILE=cdk
RUN echo "*** Building '${CONFIG_PROFILE}' profile ***"
COPY --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /var/ig
COPY --chown=forgerock:root . /var/ig
