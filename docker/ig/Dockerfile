FROM gcr.io/forgerock-io/ig/pit1:7.2.0-795bf59d334b6c6135eeeebe4c38b483cdab956b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
ARG CONFIG_PROFILE=cdk
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /var/ig
COPY --chown=forgerock:root . /var/ig
