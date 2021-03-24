FROM gcr.io/forgerock-io/ig/pit1:7.1.0-0680003d42ef1f39f156b8fa79100906a08ad312

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
