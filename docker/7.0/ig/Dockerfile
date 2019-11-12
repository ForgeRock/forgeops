FROM gcr.io/forgerock-io/ig/pit1:7.0.0-31766ee214bd5aac8ffe1e9496032da251e0befc

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
