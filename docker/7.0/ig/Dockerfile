FROM gcr.io/forgerock-io/ig/pit1:7.2.0-e65abb1127e5ea1c565ce620b4f949056e9c6fc4

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
