FROM gcr.io/forgerock-io/ig/pit1:7.1.0-d62f529ea274418b75364488844c04159089ed9a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
