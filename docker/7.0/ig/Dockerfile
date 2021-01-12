FROM gcr.io/forgerock-io/ig/pit1:7.1.0-41975efcba5839d0d9f41f8f04e844a719faf97d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
