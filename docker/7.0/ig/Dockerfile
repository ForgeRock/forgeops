FROM gcr.io/forgerock-io/ig/pit1:7.0.0-79f82d59ce38084737a206bfdc9665a87cedbe52

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
