FROM gcr.io/forgerock-io/ig/pit1:7.0.0-5a54ef330dee552dea777266b8b3f1b1a38d7c9f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
