FROM gcr.io/forgerock-io/ig/pit1:7.2.0-6948b915f93349481094a65398b09daf03224ac8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
