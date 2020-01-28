FROM gcr.io/forgerock-io/ig/pit1:7.0.0-c719f2f29fe075e30c71202d7ab76c7131999506

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
