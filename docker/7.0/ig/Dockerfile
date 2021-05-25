FROM gcr.io/forgerock-io/ig/pit1:7.2.0-138a2e4c0715162f3f8b40b2c81668fa954c9ad9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
