FROM gcr.io/forgerock-io/ig/pit1:7.1.0-7001f0796b88fe50409e6974de18d155be68c3ea

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
