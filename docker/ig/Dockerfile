FROM gcr.io/forgerock-io/ig/pit1:7.0.0-3242a6c3cdc76c7faa08fcae67a33a8cf9c65dcd

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
