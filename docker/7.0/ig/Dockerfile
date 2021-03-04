FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4eebd59f79e679c097c62cbf9d9b73d2f8db122c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
