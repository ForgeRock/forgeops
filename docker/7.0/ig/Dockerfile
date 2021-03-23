FROM gcr.io/forgerock-io/ig/pit1:7.1.0-1b86bb7ee1ec68014b53c3ad018668c977451ff5

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
