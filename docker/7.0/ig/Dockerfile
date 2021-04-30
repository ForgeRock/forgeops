FROM gcr.io/forgerock-io/ig/pit1:7.2.0-1b31b347efd06b00be82b0b4be3ae662f5bbddba

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
