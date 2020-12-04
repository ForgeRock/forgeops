FROM gcr.io/forgerock-io/ig/pit1:7.1.0-d19df6775bbc71c900cdcc9745f9b321f756e540

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
