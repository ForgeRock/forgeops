FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f4f0b779878ab4c9d31de7d46a5ad571f73813ea

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
