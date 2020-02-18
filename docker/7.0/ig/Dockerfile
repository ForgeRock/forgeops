FROM gcr.io/forgerock-io/ig/pit1:7.0.0-9fba68e7c55db4f368a71469b78d4b86330a45af

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
