FROM gcr.io/forgerock-io/ig/pit1:7.0.0-e3432fcea625fa23af09a24dea1e4ab56e151e4f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
