FROM gcr.io/forgerock-io/ig/pit1:7.1.0-8097b24c688780e225f095920328a0c584290786

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
