FROM gcr.io/forgerock-io/ig/pit1:7.1.0-dbbe78c3e09511da717212baba64009339245480

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
