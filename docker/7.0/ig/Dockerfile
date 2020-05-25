FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-94ada554c3c21ba70b8a28cb1cc6a4cf1e16c552

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
