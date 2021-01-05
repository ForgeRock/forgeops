FROM gcr.io/forgerock-io/ig/pit1:7.1.0-db141a758a2fcee2927a9ea5de95ed8dce92d595

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
