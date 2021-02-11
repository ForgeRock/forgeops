FROM gcr.io/forgerock-io/ig/pit1:7.1.0-5860a86c8a6f85882e67bcfa8e98e6d8683cd45c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
