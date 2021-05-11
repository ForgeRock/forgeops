FROM gcr.io/forgerock-io/ig/pit1:7.2.0-46906c8bcf53aca7c8f3aa02991eecad9b5cd59e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
