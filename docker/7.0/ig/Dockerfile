FROM gcr.io/forgerock-io/ig/pit1:7.2.0-4463e94b56a73a331000b8b18e38a7feb36e25d3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
