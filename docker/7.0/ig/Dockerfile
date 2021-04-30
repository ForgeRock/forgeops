FROM gcr.io/forgerock-io/ig/pit1:7.1.0-62f8a734411e128145c9a7a84ae89ec29e937063

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
