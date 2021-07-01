FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021.7-4ce9df23a86960bf53496b96b85ccb2081a265c9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
