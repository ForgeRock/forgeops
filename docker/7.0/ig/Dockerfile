FROM gcr.io/forgerock-io/ig/pit1:7.0.0-423c890017bd3443eba68e66ddab9bf44c044056

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
