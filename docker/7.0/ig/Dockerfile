FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4f241e71322088fae8bb28e5996fcd27b00f7147

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
