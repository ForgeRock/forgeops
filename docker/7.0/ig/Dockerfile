FROM gcr.io/forgerock-io/ig/pit1:7.0.0-4f559ea806897b83f2e3ecba69e9ff449bd6d89e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
