FROM gcr.io/forgerock-io/ig/pit1:7.0.0-1f3896abdf8e6fcc42a9d7abf23cde5300cceea1

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
