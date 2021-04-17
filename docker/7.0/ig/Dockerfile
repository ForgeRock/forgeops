FROM gcr.io/forgerock-io/ig/pit1:7.2.0-0bf5441640da8a45ad4edc97decb331c14ae6353

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
