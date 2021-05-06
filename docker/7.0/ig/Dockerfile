FROM gcr.io/forgerock-io/ig/pit1:7.2.0-7a6688949dad9c83a6ea1be3b562047a9594d739

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
