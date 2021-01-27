FROM gcr.io/forgerock-io/ig/pit1:7.1.0-33c26d0e0d1bd6ca1fbb12813307ddd92138151b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
