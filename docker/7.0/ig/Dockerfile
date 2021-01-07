FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2f92ce9b624e6d27bb71cbe2ca5f5d22311b63ec

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
