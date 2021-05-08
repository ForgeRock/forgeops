FROM gcr.io/forgerock-io/ig/pit1:7.2.0-13c0ae0aa5bcb8d40731517d4465db19b29d303b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
