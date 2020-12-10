FROM gcr.io/forgerock-io/ig/pit1:7.1.0-5c39ba3e59132e1c56c20b295ef39531ee3521e8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
