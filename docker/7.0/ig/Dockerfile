FROM gcr.io/forgerock-io/ig/pit1:7.0.0-bc259b88a72959b4699e6979fa843ae5bc1ebd43

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
