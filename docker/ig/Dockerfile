FROM gcr.io/forgerock-io/ig/pit1:7.0.0-1aad1e6f2dea8897bf73a722efac24ec970a5307

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
