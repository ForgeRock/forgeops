FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2a171b8f88027b43fbe6e6c0b9d495d491b3c1eb

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
