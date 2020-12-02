FROM gcr.io/forgerock-io/ig/pit1:7.1.0-ef52c49dac267f0904a715883be261a52f65add4

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
