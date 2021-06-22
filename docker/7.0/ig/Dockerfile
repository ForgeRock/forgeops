FROM gcr.io/forgerock-io/ig/pit1:7.1.1-c2aba77fc3b9903c473fe7d8fbf4e16768709c0f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
