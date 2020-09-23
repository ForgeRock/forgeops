FROM gcr.io/forgerock-io/ig/pit1:7.1.0-e59852731febb8d25fb6bb7200be970644497d36

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
