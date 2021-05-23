FROM gcr.io/forgerock-io/ig/pit1:7.2.0-ca616efc64e4581ac19f3c29f69931c9e5fd0496

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
