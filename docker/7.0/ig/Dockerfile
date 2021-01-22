FROM gcr.io/forgerock-io/ig/pit1:7.1.0-a343635a7d62d7417faf5f79d32b81ceaec7d878

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
