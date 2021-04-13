FROM gcr.io/forgerock-io/ig/pit1:7.1.0-ea56d6087853f060545c35de94417e5ffb3c2e5c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
