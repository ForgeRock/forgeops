FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-1327c64c8edf210bc0b9a5c78850a2c9f5a3d6da

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
