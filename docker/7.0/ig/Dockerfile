FROM gcr.io/forgerock-io/ig/pit1:7.2.0-777709a9b8e07dff5dc0521d4aed4f01d30ffb9d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
