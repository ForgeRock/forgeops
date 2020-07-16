FROM gcr.io/forgerock-io/ig/pit1:7.0.0-e52cdce865372d04aefc19a33aec9d898e5b09e1

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
