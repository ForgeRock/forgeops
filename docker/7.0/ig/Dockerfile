FROM gcr.io/forgerock-io/ig/pit1:7.1.0-e98e69144c99f00d08f91a8efd2a50c9346ac2ea

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
