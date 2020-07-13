FROM gcr.io/forgerock-io/ig/pit1:7.0.0-f944ff1ea2ed3bcb9e5cb06301a80ea8f16a11ff

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
