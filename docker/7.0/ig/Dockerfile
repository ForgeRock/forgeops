FROM gcr.io/forgerock-io/ig/pit1:7.0.0-62a39b1fc3c67473eb1019c1ec7343eb3009b894

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
