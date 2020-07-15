FROM gcr.io/forgerock-io/ig/pit1:7.0.0-00fa828ede64f18885ccb0979a8801f6cd9a7fb5

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
