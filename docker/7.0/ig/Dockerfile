FROM gcr.io/forgerock-io/ig/pit1:7.1.0-3245b96bbeef5711a78ecb9ed8e33c705e9ff06a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
