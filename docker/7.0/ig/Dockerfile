FROM gcr.io/forgerock-io/ig/pit1:7.1.0-a085d3618c06b24c3e44f28e3cb59b1440458118

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
