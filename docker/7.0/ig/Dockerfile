FROM gcr.io/forgerock-io/ig/pit1:7.0.0-c5c76bb469f9913934861a4c654065761ed60584

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
