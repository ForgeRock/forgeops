FROM gcr.io/forgerock-io/ig/pit1:7.1.0-875792854852c016172b4808d8aaf75f62676b65

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
