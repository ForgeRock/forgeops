FROM gcr.io/forgerock-io/ig/pit1:7.1.0-48b7ab05f84143d3b0095a221533fc39a7d99d37

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
