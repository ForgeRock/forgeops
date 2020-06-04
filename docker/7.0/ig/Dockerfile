FROM gcr.io/forgerock-io/ig/pit1:7.0.0-6faa97d05c5cd80accc34e23116e2cc040f69b5d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
