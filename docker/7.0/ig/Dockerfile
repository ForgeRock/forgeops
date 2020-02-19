FROM gcr.io/forgerock-io/ig/pit1:7.0.0-1f8a29862f8132564b3f13ed1c724ec891eeab4e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
