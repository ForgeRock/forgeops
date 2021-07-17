FROM gcr.io/forgerock-io/ig/pit1:7.2.0-3d23c0a64a8d9ec46e0e53e2ede238e9ce679fc7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
ARG CONFIG_PROFILE=cdk
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /var/ig
COPY --chown=forgerock:root . /var/ig
