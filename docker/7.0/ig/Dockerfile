FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4478568b22aecb81584ef5eb23b6e3e01e2b8662

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
