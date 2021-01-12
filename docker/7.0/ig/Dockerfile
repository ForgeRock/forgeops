FROM gcr.io/forgerock-io/ig/pit1:7.1.0-5cc857eb9d76d75027e24d99b0c78813a1bbd3c3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
